package modifaxe.builder;

#if (macro || modifaxe_runtime)

import haxe.macro.Expr;
import haxe.macro.Type;

import modifaxe.tools.ExprTools.ExprMapContext;
import modifaxe.tools.ExprTools.mapWithContext;

/**
	This processes the AST and records the required entries for `.modhx`.

	An instance of `Builder` is created for each `@:build` macro used to process a class.
**/
class Builder {
	//~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Statics ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~\\

	/**
		A list of `Builder` instances that have content.
	**/
	static var builders: Array<Builder> = [];

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
		A list of expressions to call at the start of the runtime to parse the `.modhx`.
	**/
	static var loadExpressions: Array<Expr> = [];

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

	/**
		Getter for `loadExpressions`.
	**/
	public static function extractLoaderExpressions() {
		return loadExpressions;
	}

	/**
		Returns `true` if there are any `Builder` instances that require `.modhx` generation.
	**/
	public static function shouldGenerateModHx() {
		return builders.length > 0;
	}

	/**
		Generates the content for the `.modhx` file.
		Must be called after all @:build macros have executed.
	**/
	public static function generateModHxContent(): String {
		final buf = new StringBuf();

		for(builder in builders) {
			buf.add(builder.generateModHxSections());
			buf.addChar(10);
		}

		return buf.toString();
	}

	//~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Instance ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~\\

	var currentEntries: Array<Entry> = [];
	var sections: Array<Section> = [];

	var index = 0;

	public function new() {
	}

	public function onFinishedBuilding() {
		if(hasSections()) {
			builders.push(this);
		}
	}

	/**
		Returns `true` if there is at least one section to be generated.
	**/
	public function hasSections() {
		return sections.length > 0;
	}

	/**
		Returns a processed modified version of a function field's expression.
		Returns `null` if no modifications were generated.
	**/
	public function buildFunctionExpr(cls: Null<ClassType>, field: Field, expr: Expr): Null<Expr> {
		final e = mapExpr(expr, new ExprMapContext());

		if(currentEntries.length > 0) {
			final sectionName = (cls != null ? '${cls.name}.' : "") + field.name;
			sections.push(new Section(sectionName, currentEntries));
			currentEntries = [];
			return e;
		}

		return null;
	}

	/**
		Processes an expression.

		Redirects constants to their data holding variable and record them.
	**/
	function mapExpr(expr: Expr, context: ExprMapContext): Expr {
		return switch(expr.expr) {
			case EConst(CIdent(id)) if(id == "true" || id == "false"): {
				addEntry(0, id, expr, context);
			}
			case EConst(CInt(intString, _)): {
				addEntry(1, intString, expr, context);
			}
			case EConst(CFloat(floatString, _)): {
				addEntry(2, floatString, expr, context);
			}
			case EConst(CString(string, DoubleQuotes)): {
				addEntry(3, string, expr, context);
			}
			case _: {
				mapWithContext(expr, context, mapExpr);
			}
		}
	}

	/**
		Adds an entry and returns its access expression.
	**/
	function addEntry(type: Int, content: String, expr: Expr, context: ExprMapContext) {
		final name = context.generateName();
		switch(type) {
			case 0: addBoolEntry(name, content == "true", expr);
			case 1: addIntEntry(name, content, expr);
			case 2: addFloatEntry(name, content, expr);
			case 3: addStringEntry(name, content, expr);
		}
		return macro ModifaxeData.$name;
	}

	function addBoolEntry(name: String, boolean: Bool, originalExpression: Expr) {
		currentEntries.push(new Entry(name, EBool(boolean)));
		addDataField(name, macro : Bool, originalExpression);
		loadExpressions.push(macro ModifaxeData.$name = loader.nextBool(false));
	}

	function addIntEntry(name: String, intString: String, originalExpression: Expr) {
		currentEntries.push(new Entry(name, EInt(intString)));
		addDataField(name, macro : Int, originalExpression);
		loadExpressions.push(macro ModifaxeData.$name = loader.nextInt(0));
	}

	function addFloatEntry(name: String, intString: String, originalExpression: Expr) {
		currentEntries.push(new Entry(name, EFloat(intString)));
		addDataField(name, macro : Float, originalExpression);
		loadExpressions.push(macro ModifaxeData.$name = loader.nextFloat(0.0));
	}

	function addStringEntry(name: String, intString: String, originalExpression: Expr) {
		currentEntries.push(new Entry(name, EString(intString)));
		addDataField(name, macro : String, originalExpression);
		loadExpressions.push(macro ModifaxeData.$name = loader.nextString(""));
	}

	function addDataField(name: String, complexType: ComplexType, originalExpression: Expr) {
		dataFields.push({
			name: name,
			access: [APublic, AStatic],
			pos: originalExpression.pos,
			kind: FVar(complexType, originalExpression)
		});
	}

	/**
		Generates this builder's `.modhx` content using its accumulated sections.
	**/
	public function generateModHxSections(): StringBuf {
		final buf = new StringBuf();

		for(section in sections) {
			buf.add(section.generateModHxSection());
			buf.addChar(10);
		}

		return buf;
	}
}

#end
