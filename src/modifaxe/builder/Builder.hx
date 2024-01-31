package modifaxe.builder;

#if (macro || modifaxe_runtime)

import haxe.macro.Expr;

using haxe.macro.ExprTools;

/**
	This processes the AST and records the required entries for `.modhx`.

	An instance of `Builder` is created for each `@:build` macro used to process a class.
**/
class Builder {
	//~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Statics ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~\\

	/**
		An accumulated list of fields to generate on the singleton class that
		will contain all the data at runtime.
	**/
	static var dataFields: Array<Field> = [];

	/**
		Tracks whether the data singleton fields have been accessed.

		If this is `true` while expressions are still being processed, that means
		something is wrong.
	**/
	static var hasExtractedFields: Bool = false;

	/**
		Getter for `dataFields` that can only run once.
		If it runs multiple times, that means something is wrong.
	**/
	public static function extractDataFields() {
		if(hasExtractedFields) {
			throw "Should not call this function more than once.";
		} else {
			hasExtractedFields = true;
		}
		
		final result = dataFields;
		dataFields = [];
		return result;
	}

	static var loadExpressions: Array<Expr> = [];
	public static function extractLoaderExpressions() {
		return loadExpressions;
	}

	//~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Instance ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~\\

	var currentEntries: Array<Entry> = [];
	var sections: Array<Section> = [];

	var index = 0;

	public function new() {
	}

	/**
		Returns a processed modified version of a function field's expression.
		Returns `null` if no modifications were generated.
	**/
	public function buildFunctionExpr(fieldName: String, expr: Expr): Null<Expr> {
		final e = mapExpr(expr);

		if(currentEntries.length > 0) {
			sections.push(new Section(fieldName, currentEntries));
			currentEntries = [];
			return e;
		}

		return null;
	}

	function mapExpr(expr: Expr): Expr {
		return switch(expr.expr) {
			case EConst(CInt(intString, _)): {
				final name = "number_" + (++index);
				addIntEntry(name, intString, expr);

				macro ModifaxeData.$name;
			}
			case _: expr.map(mapExpr);
		}
	}

	function addIntEntry(name: String, intString: String, originalExpression: Expr) {
		currentEntries.push(new Entry(name, EInt(intString)));
		addDataField(name, originalExpression);
		loadExpressions.push(macro ModifaxeData.$name = nextInt());
	}

	function addDataField(name: String, originalExpression: Expr) {
		dataFields.push({
			name: name,
			access: [APublic, AStatic],
			pos: originalExpression.pos,
			kind: FVar(macro : Int, originalExpression)
		});
	}

	/**
		Returns `true` if there is at least one section to be generated.
	**/
	public function hasSections() {
		return sections.length > 0;
	}

	/**
		Generates this builder's `.modhx` content using its accumulated sections.
	**/
	public function generateModHxContent(): StringBuf {
		final buf = new StringBuf();

		for(section in sections) {
			buf.add(section.generateModHxSection());
		}

		return buf;
	}
}

#end
