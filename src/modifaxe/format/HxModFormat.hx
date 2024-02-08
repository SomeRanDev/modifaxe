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
		A `Map` that accumulates the number of entries for `.modhx` files.

		The key is the file path, and the value is the entry count.
	**/
	var entryCounter: Map<String, Int> = [];

	/**
		Generates default value for `output`.
	**/
	inline function generateDefaultOutputObject() {
		return { output: new StringBuf(), entries: 0 };
	}

	/**
		Generates an expression that loads data from `.modhx` files.
	**/
	public function generateLoadExpression(files: Array<File>): Expr {
		final blockExpressions = [];

		for(file in files) {
			final expressions = [];

			final path = file.getPath(extension);

			if(!entryCounter.exists(path)) {
				entryCounter.set(path, 0);
			}
			var entryCount = entryCounter.get(path) ?? 0;

			#if macro // fix display error with $v{}
			expressions.push(
				macro final loader = modifaxe.runtime.ModParser.fromEntryCount($v{path}, $v{entryCount})
			);
			#end

			for(section in file.sections) {
				for(entry in section.entries) {

					// Get identifier for static variable with the data
					final identifier = entry.getUniqueName();

					// Expression used to load data from `.modhx` parser
					final valueExpr = switch(entry.value) {
						case EBool(_): macro loader.nextBool(false);
						case EInt(_): macro loader.nextInt(0);
						case EFloat(_): macro loader.nextFloat(0.0);
						case EString(_): macro loader.nextString("");
						case EEnum(_, enumType): generateEnumLoadingExpr(enumType, macro loader.nextEnumIdentifier(""));
					}

					// Store expression in list.
					if(valueExpr != null) {
						expressions.push(macro $i{identifier} = $valueExpr);
					}
				}

				// Increment entry count
				entryCount += section.entries.length;
			}

			// Update count
			entryCounter.set(path, entryCount);

			blockExpressions.push(macro $b{expressions});
		}

		return macro @:mergeBlock $b{blockExpressions};
	}

	/**
		Generates `.modhx` files from the provided `File`s.
		This is called after all `@:build` macros in `Context.onAfterTyping`.
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

			Output.saveContent(file.getPath(extension), buf.toString());
		}
	}
}

#end
