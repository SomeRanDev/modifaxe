package modifaxe;

#if (macro || modifaxe_runtime)

import haxe.macro.Context;

import modifaxe.builder.File;
import modifaxe.builder.Section;
import modifaxe.config.Define;
import modifaxe.format.FormatIdentifier;

class FileCollection {
	/**
		A `Map` of the files that should be generated.

		The outer map uses format's identifier as the key.
		The inner map uses the absolute file path for the key.
	**/
	var files: Map<FormatIdentifier, Map<String, File>> = [];

	/**
		This is set to `true` once a single entry has been added to `files`.
	**/
	var hasAnyFiles: Bool = false;

	/**
		Constructor.
	**/
	public function new() {
	}

    /**
        Returns `true` if no sections have been added to this collection.
    **/
    public function isEmpty() {
        return !hasAnyFiles;
    }

    /**
        Clears the entire collection.
    **/
    public function clear() {
        files = [];
    }

	/**
		Adds a section to a file given its path and format.
	**/
	public function addSectionToFile(section: Section, format: Null<FormatIdentifier>, filePath: Null<String>) {
		// Use default file path if `null`
		filePath ??= #if macro Context.definedValue(Define.DefaultFilePath) ?? #end "data";

		// Use default format if `null`
		format ??= #if macro Context.definedValue(Define.DefaultFormat) ?? #end "modhx";

		if(filePath == null || format == null) return;

		if(!files.exists(format)) {
			files.set(format, []);
		}

		final filePathMap = files.get(format);
		if(filePathMap == null) return;

		final absolutePath = filePath.length == 0 ? filePath : sys.FileSystem.absolutePath(filePath);
		if(!filePathMap.exists(absolutePath)) {
			filePathMap.set(absolutePath, new File(filePath));
			hasAnyFiles = true;
		}

		final file = filePathMap.get(absolutePath);
		if(file != null) {
			file.addSection(section);
		}
	}

    /**
		Generates an `Array` of `File`s for each format.
	**/
	public function generateFileList(): Map<FormatIdentifier, Array<File>> {
		final result: Map<FormatIdentifier, Array<File>> = [];

		for(format => fileMap in files) {
			final fileList: Array<File> = [];
			for(_ => fileObj in fileMap) {
				fileList.push(fileObj);
			}
			result.set(format, fileList);
		}

		return result;
	}
}

#end
