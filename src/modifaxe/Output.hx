package modifaxe;

#if (macro || modifaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.MacroStringTools;
import haxe.macro.Type;

import modifaxe.builder.File;
import modifaxe.builder.Section;
import modifaxe.config.Define;
import modifaxe.format.FormatIdentifier;

/**
	Singleton that manages output.
**/
class Output {
	/**
		A collection for all files, sections, and entries accumulated for
		the entire project.
	**/
	static var allFiles = new FileCollection();

	/**
		An accumulated list of fields to generate on the singleton class that
		will load the data at runtime.
	**/
	static var loaderFields: Array<TypeDefinition> = [];

	/**
		A list of all saved files.
		Used to determine if there's any old files that need to be deleted.
	**/
	static var savedFiles: Array<String> = [];

	/**
		Getter for `loaderFields`.
	**/
	public static function getLoaderFields() {
		return loaderFields;
	}

	/**
		Adds a section to the project's complete Modifaxe file collection.
	**/
	public static function addSectionToAllFiles(section: Section, format: Null<FormatIdentifier>, filePath: Null<String>) {
		allFiles.addSectionToFile(section, format, filePath);
	}

	/**
		Given an `enum` or `enum abstract` `Type`, this adds a function to the data loading singleton
		to a case of said type as a `String`.
	**/
	public static function addDataEnumLoader(enumOrAbstractType: Type, enumTypeExpressionPos: Position, enumValueExpression: Expr, defaultValueName: String) {
		static var isAdded: Map<String, Bool> = [];

		if(isAdded.exists(Std.string(enumOrAbstractType))) {
			return;
		}

		final cases = getCaseDataFromBaseType(enumOrAbstractType, enumTypeExpressionPos, defaultValueName);
		if(cases == null) {
			return;
		}

		final switchExpr = {
			expr: ESwitch(macro name, cases.slice(1), cases[0].expr),
			pos: enumValueExpression.pos
		}

		final name = getFunctionForEnumType(enumOrAbstractType);
		if(name == null) {
			return;
		}

		final functionTD = {
			name: "Modifaxe_" + (name : String),
			pos: enumTypeExpressionPos,
			pack: ["modifaxe", "enumloaders"],
			fields: [{
				name: (name : String),
				access: [APublic, AStatic],
				pos: enumTypeExpressionPos,
				kind: FFun({
					args: [{ name: "name", type: macro : String }],
					expr: macro return $switchExpr
				})
			}],
			kind: TDClass(null, null, false, true, false),

			#if !modifaxe_make_enum_loaders_reflective
			// This class is used internally, so let's optimize it a little.
			meta: [
				{ name: ":unreflective", pos: enumTypeExpressionPos },
				{ name: ":nativeGen", pos: enumTypeExpressionPos }
			]
			#end
		};

		#if macro
		Context.defineType(functionTD);
		#end
	}

	/**
		Given a `Type` that's a `TEnum` or `TAbstract`, returns a list of `Case`s for each
		enum case or enum abstract variable.

		The case conditional value being the `String` name of the enum case, the return value
		being the actual enum value.
	**/
	static function getCaseDataFromBaseType(enumOrAbstractType: Type, errorPos: Position, defaultCaseName: String): Array<Case> {
		var enumType = null;
		var abstractType = null;
		switch(enumOrAbstractType) {
			case TEnum(_.get() => e, []): enumType = e;
			case TAbstract(_.get() => absType, []) if(absType.meta.has(":enum")): abstractType = absType;
			case t: #if macro Context.error("Invalid Modifaxe enum type " + t, errorPos); #end
		}

		var defaultCase = null;

		final identifiers: Null<Array<{ name: String, expr: Expr }>> = if(enumType != null) {
			// Get list of enum cases
			final result = [];
			for(name => field in enumType.constructs) {
				final enumTypePath = getBaseTypePathAsExpr(enumType);
				switch(field.type) {
					case TEnum(_, []): {
						final c = { name: name, expr: macro $enumTypePath.$name };
						if(defaultCaseName == name) defaultCase = c;
						result.push(c);
					}
					case _:
				}
			}
			result;
		} else if(abstractType != null && abstractType.impl != null) {
			// Get list of enum abstract variables
			[
				for(f in abstractType.impl.get().statics.get()) {
					final abstractTypePath = getBaseTypePathAsExpr(abstractType);
					final name = f.name;
					final c = { name: name, expr: macro $abstractTypePath.$name };
					if(defaultCaseName == name) defaultCase = c;
					c;
				}
			];
		} else {
			null;
		}

		if(defaultCase == null || identifiers == null) {
			return [];
		}

		return [
			for(ident in [(defaultCase : { name: String, expr: Expr })].concat(identifiers)) {
				{ values: [#if macro macro $v{ident.name} #end], expr: ident.expr }
			}
		];
	}

	/**
		Converts a `BaseType` to its dot-path `Expr`.
	**/
	static function getBaseTypePathAsExpr(baseType: BaseType) {
		final fields = baseType.pack.copy();
		if(baseType.module != baseType.name) {
			fields.push(baseType.module);
		}
		fields.push(baseType.name);
		return MacroStringTools.toFieldExpr(fields);
	}

	/**
		Generates the unique "loader" function name for the `enumType` provided.
	**/
	public static function getFunctionForEnumType(enumType: Type): Null<String> {
		final baseType: Null<BaseType> = switch(enumType) {
			case TEnum(_.get() => e, []): e;
			case TAbstract(_.get() => a, []): a;
			case _: null;
		}

		if(baseType == null) {
			return null;
		}

		final buf = new StringBuf();
		buf.add("load_");
		for(p in baseType.pack) {
			buf.add(p);
			buf.add("_");
		}
		buf.add(baseType.name);
		return buf.toString();
	}

	/**
		Returns `true` if files need to be generated for this compilation.
	**/
	public static function shouldGenerate() {
		return !allFiles.isEmpty();
	}

	/**
		Returns result of `generateFileList` for all `File`s.
	**/
	public static function generateFileList(): Map<FormatIdentifier, Array<File>> {
		return allFiles.generateFileList();
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
