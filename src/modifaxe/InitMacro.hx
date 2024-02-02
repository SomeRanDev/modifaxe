package modifaxe;

#if (macro || modifaxe_runtime)

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

import modifaxe.Output;
import modifaxe.builder.Builder;
import modifaxe.format.Format;
import modifaxe.format.HxModFormat;

function init() {
	#if macro

	// Do not run in IDE
	if(Context.defined("display")) {
		return;
	}

	// Apply our @:build macro where it's needed
	Compiler.addGlobalMetadata("", "@:build(modifaxe.BuildMacro.build())");

	// Register the `.modhx` format
	Format.registerFormat("modhx", new HxModFormat());

	// Special technique to generate code post-@:build macros
	// Hope this is okay???
	Context.onTypeNotFound(function(name) {
		return switch(name) {
			case "ModifaxeData": makeModifaxeData();
			case "ModifaxeLoader": makeModifaxeLoader();
			case _: null;
		}
	});

	#end
}

#if macro

/**
	Generate class that stores Modifaxe data.
**/
function makeModifaxeData(): TypeDefinition {
	return {
		name: "ModifaxeData",
		pack: [],
		pos: Context.currentPos(),
		fields: Output.extractDataFields(),
		kind: TDClass(null, [], false, true, false)
	}
}

/**
	Generate function that loads Modifaxe data.
**/
function makeModifaxeLoader(): TypeDefinition {
	// Process all files and store their load expressions
	final loadExpressions = [];
	for(formatIdent => fileList in Output.generateFileList()) {
		final format = formatIdent.getFormat();
		format.saveModFiles(fileList); // Saves the mod files for this format
		loadExpressions.push(format.generateLoadExpression(fileList)); // Generate loading code
	}

	// Generate the contents of `ModifaxeLoader.load`.
	final loadExpr = if(loadExpressions.length > 0) {
		macro $b{loadExpressions}
	} else {
		macro {}
	}

	// Generate TypeDefinition
	final result = macro class ModifaxeLoader {
		public static function load() $loadExpr;
	}

	Output.trackAndDeleteOldFiles();

	return result;
}

#end

#end
