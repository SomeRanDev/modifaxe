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
