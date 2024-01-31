package modifaxe.builder;

#if (macro || modifaxe_runtime)

/**
	Represents a `.modhx` section.
**/
class Section {
	var name: String;
	var entries: Array<Entry> = [];

	public function new(name: String, entries: Array<Entry>) {
		this.name = name;
		this.entries = entries;
	}

	/**
		Generates this section's `.modhx` content using its accumulated entries.
	**/
	public function generateModHxSection(): StringBuf {
		final buf = new StringBuf();

		buf.add("[");
		buf.add(name);
		buf.add("]\n");

		for(entry in entries) {
			buf.add(entry.value.toTypeString());
			buf.add(".");
			buf.add(entry.name);
			buf.add(": ");
			buf.add(entry.value.toValueString());
			buf.add("\n");
		}

		return buf;
	}
}

#end
