package modifaxe.config;

#if (macro || modifaxe_runtime)

enum abstract Define(String) from String to String {
	/**
		-D modifaxe_modhx_path=FILE_PATH

		Configures the file path the `.modhx` is generated at.
	**/
	var ModHxPath = "modifaxe_modhx_path";

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
