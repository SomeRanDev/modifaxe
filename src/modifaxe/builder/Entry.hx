package modifaxe.builder;

#if (macro || modifaxe_runtime)

/**
	Represents a `.modhx` entry.
**/
class Entry {
	public var name(default, null): String;
	public var value(default, null): EntryValue;

	public function new(name: String, value: EntryValue) {
		this.name = name;
		this.value = value;
	}
}

#end
