package modifaxe.config;

#if (macro || modifaxe_runtime)

/**
	A list of all the defines in Modifaxe.
**/
enum abstract Define(String) from String to String {
	/**
		-D modifaxe_default_file_path=FILE_PATH

		Default value: "data"

		Configures the default file path the data file is generated at.
	**/
	var DefaultFilePath = "modifaxe_default_file_path";

	/**
		-D modifaxe_default_format=FORMAT_NAME

		Default value: "modhx"

		Configures the default format used by mod files.
	**/
	var DefaultFormat = "modifaxe_default_format";

	/**
		-D modifaxe_path_filter=PATH

		Default value: ""

		The path filter applied to the `addGlobalMetadata` function that sets up the
		`@:build` macro. Use this to optimize the build macro to only check in a
		specific package or module.

		Use `--macro Modifaxe.addPath(pathFilter)` to add an additional path.
	**/
	var PathFilter = "modifaxe_path_filter";

	/**
		-D modifaxe_dont_delete_old_files

		If defined, old data files will not be deleted and the `.modifaxe` tracking file will
		not be generated.
	**/
	var DontDeleteOldFiles = "modifaxe_dont_delete_old_files";

	/**
		-D modifaxe_old_file_tracker_name=FILE_PATH

		Default value: ".modifaxe"

		This is the name and path of the file that stores a list of generated files.
	**/
	var OldFileTrackerName = "modifaxe_old_file_tracker_name";

	/**
		-D modifaxe_use_relative_path

		By default, the data file path injected into the code is the absolute path of the generated file.
		If this is defined, the user-specified path will be used verbatim.
	**/
	var UseRelativePath = "modifaxe_use_relative_path";

	/**
		-D modifaxe_make_enum_loaders_reflective

		If defined, the generated enum-loading classes will not have `@:nativeGen` and `@:unreflective`.
	**/
	var MakeEnumLoaderReflective = "modifaxe_make_enum_loaders_reflective";

	/**
		-D modifaxe_parser_no_map_cache

		If defined, disables the use of `Map` to cache `.modhx` parsers and their entry positions.
		Useful for custom targets with minimal API support.
	**/
	var ParserNoMapCache = "modifaxe_parser_no_map_cache";

	/**
		-D modifaxe_no_error_check

		Disables error checking on `.modhx` parsing (improves performance).
	**/
	var ParserNoErrorCheck = "modifaxe_parser_no_error_check";

	/**
		-D modifaxe_parser_use_string_concat

		Uses string concatenation to generate the resulting `String` object when parsing
		a `String` from `.modhx`.
	**/
	var ParserUseStringConcat = "modifaxe_parser_use_string_concat";

	/**
		-D modiflaxe_no_dynamic_functions

		Disables `dynamic` functions in Modifaxe runtime code.
	**/
	var NoDynamicFunctions = "modiflaxe_no_dynamic_functions";
}

#end
