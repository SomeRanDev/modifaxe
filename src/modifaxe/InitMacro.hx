package modifaxe;

#if (macro || modifaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Type;

import modifaxe.Output;
import modifaxe.config.Define;
import modifaxe.format.Format;
import modifaxe.format.HxModFormat;

function init() {
	#if macro

	// Do not run in IDE
	if(Context.defined("display")) {
		return;
	}

	// Register the `.modhx` format
	Format.registerFormat("modhx", new HxModFormat());

	// Apply `@:build` meta to path filter
	Modifaxe.addPath(Context.definedValue(Define.PathFilter) ?? "");

	// Save data files
	Context.onAfterTyping(onAfterTyping);

	#end
}

/**
	Called after all `@:build` macros.
**/
function onAfterTyping(_: Array<ModuleType>) {
	// Process all files and store their load expressions
	for(formatIdent => fileList in Output.generateFileList()) {
		final format = formatIdent.getFormat();
		if(format != null) {
			format.saveModFiles(fileList); // Saves the mod files for this format
		}
	}
}

#end
