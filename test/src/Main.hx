package;

function main() {
	ModifaxeLoader.load();
	trace(getValue());
}

@:modifaxe
function getValue() {
	return 123;
}
