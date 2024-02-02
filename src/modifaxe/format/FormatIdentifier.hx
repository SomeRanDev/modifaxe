package modifaxe.format;

#if (macro || modifaxe_runtime)

/**
	A unique identifier for each format.

	Validates a format exists upon creation.
**/
abstract FormatIdentifier(String) {
	public function new(id: String) {
		id = id.toLowerCase();

		if(!Format.formats.exists(id)) {
			throw 'Format "$id" does not exist!';
		}

		this = id;
	}

	/**
		Returns the `Format` this identifier is associated with.
	**/
	public function getFormat() {
		final result = Format.formats.get(this);
		if(result == null) {
			throw 'Could not locate format "$this".';
		}
		return result;
	}

	/**
		Handles conversion from `String`.
	**/
	@:from
	public static function fromString(s: String) {
		return new FormatIdentifier(s);
	}
}

#end
