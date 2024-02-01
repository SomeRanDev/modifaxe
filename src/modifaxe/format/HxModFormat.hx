package modifaxe.format;

#if (macro || modifaxe_runtime)

import haxe.macro.Expr;

import modifaxe.builder.File;

/**
	The implementation of the `.modhx` file format.
**/
class HxModFormat extends Format {
	/**
		The file extension used by this format.
	**/
	static var extension = "modhx";

	/**
		Generates `.modhx` files from the provided `File`s.
	**/
	public function saveModFiles(files: Array<File>): Void {
		for(file in files) {
			final buf = new StringBuf();

			for(section in file.sections) {
				buf.addChar(91); // [
				buf.add(section.name);
				buf.addChar(93); // ]
				buf.addChar(10); // \n
				
				for(entry in section.entries) {
					buf.addChar(entry.value.toTypeCharCode());
					buf.addChar(46); // .
					buf.add(entry.name);
					buf.addChar(58); // :
					buf.addChar(32); // [space]
					buf.add(entry.value.toValueString());
					buf.addChar(10); // \n
				}

				buf.addChar(10); // \n
			}

			sys.io.File.saveContent(file.getPath(extension), buf.toString());
		}
	}

	/**
		Generates an expression that loads data from `.modhx` files.
	**/
	public function generateLoadExpression(files: Array<File>): Expr {
		final blockExpressions = [];

		for(file in files) {
			final expressions = [];

			final path = file.getPath(extension);
			#if macro // fix display error with $v{}
			expressions.push(
				macro final loader = new modifaxe.runtime.ModParser($v{path})
			);
			#end

			for(section in file.sections) {
				for(entry in section.entries) {
					// Get identifier in `ModifaxeLoader`
					final identifier = entry.getUniqueName();

					// Expression used to load data from `.modhx` parser
					final valueExpr = switch(entry.value) {
						case EBool(_): macro loader.nextBool(false);
						case EInt(_): macro loader.nextInt(0);
						case EFloat(_): macro loader.nextFloat(0.0);
						case EString(_): macro loader.nextString("");
					}

					// Store expression in list.
					expressions.push(macro ModifaxeData.$identifier = $valueExpr);
				}
			}

			blockExpressions.push(macro $b{expressions});
		}

		return macro @:mergeBlock $b{blockExpressions};
	}
}

#end
