package modifaxe.format;

#if (macro || modifaxe_runtime)

import haxe.macro.Expr;

import modifaxe.builder.File;

/**
	The base class for a Modifaxe format.

	Its abstract functions allow for control over how the "mod" file is
	saved and the expressions used to load at runtime.
**/
abstract class Format {
	public static var formats(default, null): Map<String, Format> = [];

	/**
		Registers a format for Modifaxe.

		`name` should be a unique identifier for your format.
		Assign the `Format` argument `name` in `@:modifaxe` to use the format.
	**/
	public static function registerFormat(name: String, format: Format) {
		// Ignore capitalization
		name = name.toLowerCase();

		if(formats.exists(name)) {
			throw "Cannot register format with same name twice.";
		}
		formats.set(name, format);
	}

	/**
		Constructor. No need to create one in child classes, but you can if you want.
	**/
	public function new() {
	}

	/**
		Once all `@:build` macros have run, this is called to save the accumulated `File`
		objects in your desired format.

		Simply use `sys.io.File` `saveContent` or `saveBytes` to save the file.
	**/
	public abstract function saveModFiles(files: Array<File>): Void;

	/**
		Generates the `Expr` for the `ModifaxeLoader.load` function.

		Use this to generate the runtime code to read and parse your desired format.
	**/
	public abstract function generateLoadExpression(files: Array<File>): Expr;
}

#end
