package modifaxe;

#if (macro || modifaxe_runtime)

import haxe.macro.Compiler;
import haxe.macro.Context;

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

				// Generate the contents of `ModifaxeLoader.load`.
				final loaderExpressions = Builder.extractLoaderExpressions();
				final loadExpr = if(loaderExpressions.length > 0) {
					macro {
						final data = sys.io.File.getContent("data.modhx");

						final lines = data.split("\n");
						var index = 0;
						
						function nextLine() return lines[index++];
						function nextInt() return Std.parseInt(nextLine());

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
