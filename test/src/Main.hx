package;

function main() {
	ModifaxeLoader.load();
	trace(getValue());
	trace(getNumValue());
}

@:modifaxe
function getValue(): String {
	return "Hello world!";
}

@:modifaxe(File="Something")
function getNumValue() {
	final calculate = 123 + @:mod(lefthing) 321;
	return calculate / 0.5;
}
