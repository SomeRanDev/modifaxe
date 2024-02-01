package;

class Modifaxe {
	public static function init() {
		#if macro
		throw "This function should be called at runtime.";
		#end
	}
}
