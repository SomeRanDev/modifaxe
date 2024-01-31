package modifaxe;

#if (macro || modifaxe_runtime)

import haxe.macro.Compiler;
import haxe.macro.Context;

import modifaxe.Output;
import modifaxe.builder.Builder;

function init() {
	#if macro

	// Do not run on display
	if(Context.defined("display")) {
		return;
	}

	Compiler.addGlobalMetadata("", "@:build(modifaxe.BuildMacro.build())");

	Context.onTypeNotFound(function(name) {
		switch(name) {
			case "ModifaxeData": {
				return {
					name: "ModifaxeData",
					pack: [],
					pos: Context.currentPos(),
					fields: Builder.extractDataFields(),
					kind: TDClass(null, [], false, true, false)
				}
			}
			case "ModifaxeLoader": {
				Output.generateModHx();

				// Generate the contents of `ModifaxeLoader.load`.
				final loaderExpressions = Builder.extractLoaderExpressions();
				final loadExpr = if(loaderExpressions.length > 0) {
					macro {
						final loader = new modifaxe.runtime.ModParser($v{Output.getOutputPath()});
						$b{loaderExpressions}
					};
				} else {
					macro {}
				}

				// Generate TypeDefinition
				return macro class ModifaxeLoader {
					public static function load() $loadExpr;
				}
			}
		}

		return null;
	});

	#end
}

#end
