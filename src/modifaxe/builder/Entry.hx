package modifaxe.builder;

#if (macro || modifaxe_runtime)

/**
	Represents a `.modhx` entry.
**/
class Entry {
	public var name(default, null): String;
	public var value(default, null): EntryValue;

	var section: Section;

	public function new(name: String, value: EntryValue, section: Section) {
		this.name = name;
		this.value = value;
		this.section = section;
	}

	/**
		Generates a unique identifier for this entry.
		Should be used as the identifier for the entry in the runtime data singleton.
	**/
	public function getUniqueName() {
		return section.identifierSafeName() + "_" + name;
	}
}

#end
