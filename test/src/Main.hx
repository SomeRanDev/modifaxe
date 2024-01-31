package;

function main() {
	ModifaxeLoader.load();
	trace(getValue());
}

@:modifaxe
function getValue(): Float {
	return 44.4;
}
