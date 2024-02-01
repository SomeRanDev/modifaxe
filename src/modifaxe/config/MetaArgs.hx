package modifaxe.config;

#if (macro || modifaxe_runtime)

/**
	A list of all the argument that can be used in @:modifaxe.
**/
enum abstract MetaArgs(String) from String to String {
	/**
		ModOnly

		Makes it so only constant expressions with `@:mod` are generated.
	**/
	var ModOnly = "ModOnly";
}

#end
