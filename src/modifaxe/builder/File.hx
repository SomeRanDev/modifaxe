package modifaxe.builder;

#if (macro || modifaxe_runtime)

/**
	Represents a file containing sections and entries.
**/
class File {
	public var sections(default, null): Array<Section> = [];

	var originalPath: String;
	var generatedPath: Null<String> = null;

	/**
		`path` should be the file's path without configurations.
		If the file should use the default path, `null` should be passed.
	**/
	public function new(path: String) {
		if(path.length == 0) {
			throw "Path must not be empty.";
		}

		originalPath = path;
	}

	/**
		Returns the path for the file with all configurations applied.

		This includes whether the path should be absolute/relative or within any sub-folders.
	**/
	public function getPath(fileExtension: String): String {
		if(generatedPath == null) {
			generatedPath = Output.generateOutputPath(originalPath);
		}
		return haxe.io.Path.withExtension(generatedPath, fileExtension);
	}

	/**
		Used internally to add sections to a `File` while processing expressions.
	**/
	public function addSection(section: Section) {
		this.sections.push(section);
	}
}

#end
