package modifaxe.config;

#if (macro || modifaxe_runtime)

/**
	A list of all the metadata in Modifaxe.
**/
enum abstract Meta(String) from String to String {
	/**
		@:modifaxe(...args: MetaArgs)

		Marks a class or function to be processed by Modifaxe.
	**/
	var Modifaxe = ":modifaxe";

	/**
		@:mod(name: Null<String> = null)

		Sets a constant expression's name for its entry.
		Can be used without specifying a name, which is useful in `ModOnly` mode.
	**/
	var Mod = ":mod";
}

#end
