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
		-D modifaxe_use_relative_path

		By default, the `.modhx` path injected into the code is the absolute path of the generated file.
		If this is defined, the user-specified path will be used verbatim.
	**/
	var UseRelativePath = "modifaxe_use_relative_path";

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
