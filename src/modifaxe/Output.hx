package modifaxe;

#if (macro || modifaxe_runtime)

import haxe.macro.Context;

import modifaxe.builder.Builder;
import modifaxe.config.Define;

/**
	Manages output.
**/
class Output {
	/**
		Returns the path the `.modhx` file should be generated and read from.
	**/
	public static function getOutputPath(): String {
		static var cachedPath: Null<String> = null;
		if(cachedPath != null) {
			return cachedPath;
		}

		var path = #if macro Context.definedValue(Define.ModHxPath) #else null #end;

		if(path == null) {
			path = "data.modhx";
		}

		final useRelativePath = #if macro Context.defined(Define.UseRelativePath) #else false #end;
		if(!useRelativePath) {
			path = sys.FileSystem.absolutePath(path);
		}

		cachedPath = path;
		return path;
	}

	public static function generateModHx() {
		if(Builder.shouldGenerateModHx()) {
			sys.io.File.saveContent(getOutputPath(), Builder.generateModHxContent());
		}
	}
}

#end
