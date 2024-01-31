package;

function main() {
	ModifaxeLoader.load();
	trace(getValue());
}

@:modifaxe
function getValue(): String {
	return "Hello world!";
}
