package modifaxe.builder;

#if (macro || modifaxe_runtime)

/**
	Represents a section in a Modifaxe data file.
**/
class Section {
	public var name(default, null): String;
	public var entries(default, null): Array<Entry> = [];

	public function new(name: String) {
		this.name = name;
	}

	/**
		Checks if any entries have been added.
	**/
	public function hasEntries() {
		return entries.length > 0;
	}

	/**
		Used internally to add entries to a `Section` while processing expressions.
	**/
	public function addEntry(name: String, value: EntryValue) {
		final e = new Entry(name, value, this);
		entries.push(e);
		return e;
	}

	/**
		Returns a version of `name` that's safe to use as a Haxe identifier.
	**/
	public function identifierSafeName(): String {
		return StringTools.replace(name, ".", "_");
	}
}

#end
