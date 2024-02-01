package modifaxe.format;

#if (macro || modifaxe_runtime)

/**
	A unique identifier for each format.

	Validates a format exists upon creation.
**/
abstract FormatIdentifier(String) from String {
	public function new(id: String) {
		id = id.toLowerCase();

		if(!Format.formats.exists(id)) {
			throw 'Format "$id" does not exist!';
		}

		this = id;
	}

	public function getFormat() {
		final result = Format.formats.get(this);
		if(result == null) {
			throw 'Could not locate format "$this".';
		}
		return result;
	}
}

#end
