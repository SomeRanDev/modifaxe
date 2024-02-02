package modifaxe;

#if (macro || modifaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;

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

	/**
		A list of all saved files.
		Used to determine if there's any old files that need to be deleted.
	**/
	static var savedFiles: Array<String> = [];

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

	/**
		A wrapper for `sys.io.File.saveContent`.
		Tracks the file so it can be deleted later if necessary.
	**/
	public static function saveContent(path: String, content: String) {
		savedFiles.push(path);
		sys.io.File.saveContent(path, content);
	}

	/**
		A wrapper for `sys.io.File.saveBytes`.
		Tracks the file so it can be deleted later if necessary.
	**/
	public static function saveBytes(path: String, bytes: haxe.io.Bytes) {
		savedFiles.push(path);
		sys.io.File.saveBytes(path, bytes);
	}

	/**
		Called at the end of Modifaxe.
		Checks if there are any old files that weren't regenerated and deletes them.
		This function can be disabled with `-D modifaxe_dont_delete_old_files`.
	**/
	public static function trackAndDeleteOldFiles() {
		#if macro
		if(Context.defined(Define.DontDeleteOldFiles)) {
			return;
		}
		#end

		final modifaxeTrackerFilename = #if macro Context.definedValue(Define.OldFileTrackerName) ?? #end ".modifaxe";
		final oldFileList = if(sys.FileSystem.exists(modifaxeTrackerFilename)) {
			final content = sys.io.File.getContent(modifaxeTrackerFilename);
			content.split("\n").filter(p -> StringTools.trim(p).length > 0);
		} else {
			[];
		}

		final toBeDeleted = [];
		final newFiles = [];

		for(file in savedFiles) {
			final absolutePath = sys.FileSystem.absolutePath(file);
			newFiles.push(absolutePath);
		}

		for(oldFile in oldFileList) {
			if(!newFiles.contains(oldFile)) {
				toBeDeleted.push(oldFile);
			}
		}

		for(oldFile in toBeDeleted) {
			sys.FileSystem.deleteFile(oldFile);
		}

		sys.io.File.saveContent(modifaxeTrackerFilename, newFiles.join("\n"));
	}
}

#end
