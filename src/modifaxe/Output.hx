package modifaxe;

#if (macro || modifaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;

import modifaxe.builder.Builder;
import modifaxe.builder.Entry;
import modifaxe.builder.File;
import modifaxe.builder.Section;
import modifaxe.config.Define;
import modifaxe.format.FormatIdentifier;

/**
	Singleton that manages output.
**/
class Output {
	/**
		A `Map` of the files that should be generated.

		The outer map uses format's identifier as the key.
		The inner map uses the absolute file path for the key.
	**/
	static var files: Map<FormatIdentifier, Map<String, File>> = [];

	/**
		This is set to `true` once a single entry has been added to `files`.
	**/
	static var hasAnyFiles: Bool = false;

	/**
		An accumulated list of fields to generate on the singleton class that
		will contain all the data at runtime.
	**/
	static var dataFields: Array<Field> = [];

	// /**
	// 	Tracks whether the data singleton fields have been accessed.

	// 	If this is `true` while expressions are still being processed, that means
	// 	something is wrong.
	// **/
	

	// /**
	// 	A list of expressions to call at the start of the runtime to parse the `.modhx`.
	// **/
	// static var loadExpressions: Array<Expr> = [];

	/**
		Getter for `dataFields` that can only run once.
		If it runs multiple times, that means something is wrong.
	**/
	public static function extractDataFields() {
		static var hasExtractedFields: Bool = false;

		if(hasExtractedFields) {
			throw "Should not call this function more than once.";
		} else {
			hasExtractedFields = true;
		}
		
		final result = dataFields;
		dataFields = [];
		return result;
	}

	/**
		Adds a section to a file given its path and format.
	**/
	public static function addSectionToFile(section: Section, format: Null<FormatIdentifier>, filePath: Null<String>) {
		// Use default file path if `null`
		filePath ??= #if macro Context.definedValue(Define.DefaultFilePath) ?? #end "data";

		// Use default format if `null`
		format ??= #if macro Context.definedValue(Define.DefaultFormat) ?? #end "modhx";

		if(!files.exists(format)) {
			files.set(format, []);
		}

		final filePathMap = files.get(format);
		if(filePathMap == null) return;

		final absolutePath = filePath.length == 0 ? filePath : sys.FileSystem.absolutePath(filePath);
		if(!filePathMap.exists(absolutePath)) {
			filePathMap.set(absolutePath, new File(filePath));
			hasAnyFiles = true;
		}

		final file = filePathMap.get(absolutePath);
		if(file != null) {
			file.addSection(section);
		}
	}

	public static function addDataField(field: Field) {
		dataFields.push(field);
	}

	// public static function addLoadExpression(entry: Entry) {
	// 	final assignTo = switch(entry.value) {
	// 		case EBool(_): macro loader.nextBool(false);
	// 		case EInt(_): macro loader.nextInt(0);
	// 		case EFloat(_): macro loader.nextFloat(0.0);
	// 		case EString(_): macro loader.nextString("");
	// 	}

	// 	final name = entry.name;
	// 	//loadExpressions.push(macro ModifaxeData.$name = $assignTo);
	// }

	/**
		Getter for `loadExpressions`.
	**/
	// public static function extractLoaderExpressions() {
	// 	return loadExpressions;
	// }

	/**
		Returns `true` if there are any `Builder` instances that require `.modhx` generation.
	**/
	public static function shouldGenerateModHx() {
		return hasAnyFiles;
	}

	/**
		Returns `true` if there are any `Builder` instances that require `.modhx` generation.
	**/
	public static function generateFileList(): Map<FormatIdentifier, Array<File>> {
		final result: Map<FormatIdentifier, Array<File>> = [];

		for(format => fileMap in files) {
			final fileList: Array<File> = [];
			for(_ => fileObj in fileMap) {
				fileList.push(fileObj);
			}
			result.set(format, fileList);
		}

		return result;
	}

	/**
		Returns the path the `.modhx` file should be generated and read from.
	**/
	public static function generateOutputPath(file: Null<String>): String {
		// Load value for default path once
		static var defaultFilePath = #if macro Context.definedValue(Define.DefaultFilePath) #else null #end;

		// Use specified file path if it exists, default otherwise
		var path = file ?? (defaultFilePath ?? "data");

		// Generate absolute path if not using relative paths
		final useRelativePath = #if macro Context.defined(Define.UseRelativePath) #else false #end;
		if(!useRelativePath) {
			path = sys.FileSystem.absolutePath(path);
		}

		return path;
	}

	public static function generateModHx() {
		// if(Builder.shouldGenerateModHx()) {
		// 	sys.io.File.saveContent(getOutputPath(), Builder.generateModHxContent());
		// }
	}
}

#end
