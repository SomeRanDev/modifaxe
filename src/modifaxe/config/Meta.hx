package modifaxe.config;

#if (macro || modifaxe_runtime)

enum abstract Meta(String) from String to String {
	/**
		@:modifaxe

		Marks a class or function to be processed by Modifaxe.
	**/
	var Modifaxe = ":modifaxe";
}

#end
