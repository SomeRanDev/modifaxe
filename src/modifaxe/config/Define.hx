package modifaxe.config;

enum abstract Define(String) from String to String {
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
