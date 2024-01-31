package modifaxe.config;

enum abstract Define(String) from String to String {
	/**
		-D modiflaxe_no_dynamic_functions

		Disables `dynamic` functions in Modifaxe runtime code.
	**/
	var NoDynamicFunctions = "modiflaxe_no_dynamic_functions";
}
