package modifaxe.builder;

#if (macro || modifaxe_runtime)

/**
	A union type for all the values that are supported by Modifaxe.
**/
@:using(modifaxe.builder.EntryValue.EntryValueFunctions)
enum EntryValue {
	EBool(value: Bool);
	EInt(intString: String);
	EFloat(floatString: String);
	EString(string: String);
}

/**
	The functions for `EntryValue`.
**/
class EntryValueFunctions {
	public static function toTypeString(v: EntryValue) {
		return switch(v) {
			case EBool(_): "b";
			case EInt(_): "i";
			case EFloat(_): "f";
			case EString(_): "s";
		}
	}

	public static function toTypeCharCode(v: EntryValue) {
		return switch(v) {
			case EBool(_): 98;
			case EInt(_): 105;
			case EFloat(_): 102;
			case EString(_): 115;
		}
	}

	public static function toValueString(v: EntryValue) {
		return switch(v) {
			case EBool(value): value ? "true" : "false";
			case EInt(intString): intString;
			case EFloat(floatString): floatString;
			case EString(string): '"$string"';
		}
	}
}

#end
