package;

import haxe.macro.Compiler;

/**
	The main Modifaxe class.
	Primarily used for additional configuration in a project's `.hxml` file.
**/
class Modifaxe {
	/**
		Applies the Modifaxe build macro to a path filter.

		This already runs once with the value of `-D modifaxe_path_filter`, but can be
		run additional times to add additional support for other packages.
	**/
	public static function addPath(path: String) {
		#if macro
		Compiler.addGlobalMetadata(path, "@:build(modifaxe.BuildMacro.build())");
		#end
	}
}
