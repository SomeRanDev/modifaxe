package modifaxe.builder;

#if (macro || modifaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.PositionTools;
import haxe.macro.Type;

import modifaxe.config.Meta;
import modifaxe.format.FormatIdentifier;
import modifaxe.tools.ExprTools.ExprMapContext;
import modifaxe.tools.ExprTools.mapWithContext;

typedef ModifaxeState = {
	modOnly: Bool,
	file: Null<String>,
	format: Null<FormatIdentifier>
}

/**
	This processes the AST and records the required entries for the data file.

	An instance of `Builder` is created for each `@:build` macro used to process a class.
**/
class Builder {
	var currentEntries: Array<Entry> = [];
	var currentSection: Null<Section> = null;
	var currentNames: Map<String, Bool> = [];

	var files = new FileCollection();

	var state: Array<ModifaxeState> = [];

	var index = 0;

	/**
		An accumulated list of fields to generate on the singleton class that
		will contain all the data at runtime.
	**/
	var staticDataFields: Array<Field> = [];

	public function new() {
	}

	/**
		Generates the default argument state.
	**/
	function getDefaultState(): ModifaxeState {
		return {
			modOnly: false,
			file: null,
			format: null
		}
	}

	/**
		The current state. This should be an accumulation of the previous states.
	**/
	function getState(): ModifaxeState {
		return if(state.length == 0) {
			getDefaultState();
		} else {
			state[state.length - 1];
		}
	}

	/**
		Takes the arguments from the `@:modifaxe` metadata and applies it to the state stack.
	**/
	public function setArguments(args: Array<Expr>) {
		final newState = Reflect.copy(getState()); // modify a copy of the current state

		if(newState == null) throw "Reflect.copy failed."; // Required by null-safety, this can never happen.

		for(arg in args) {
			switch(arg) {
				case macro ModOnly: {
					newState.modOnly = true;
				}
				case macro File=$path: {
					final filePath = switch(path.expr) {
						case EConst(CString(path, _)): path;
						case _: {
							#if macro
							Context.error("The 'File' value should be a String expression.", arg.pos);
							#else null; #end
						}
					}
					newState.file = filePath != null && filePath.length == 0 ? null : filePath;
				}
				case macro Format=$formatName: {
					final formatIdent = switch(formatName.expr) {
						case EConst(CString(name, _) | CIdent(name)): name;
						case _: {
							#if macro
							Context.error("The 'Format' value should be an identifier or String expression.", arg.pos);
							#else null; #end
						}
					}
					if(formatIdent != null && formatIdent.length > 0) {
						newState.format = formatIdent;
					}
				}
				case _: {
					#if macro
					Context.error("Unknown argument.", arg.pos);
					#end
				}
			}
		}

		state.push(newState);
	}

	/**
		Pops the state of the `@:modifaxe` arguments.
	**/
	public function popArguments() {
		state.pop();
	}

	/**
		Returns a processed modified version of a function field's expression.
		Returns `null` if no modifications were generated.
	**/
	public function buildFunctionExpr(cls: Null<ClassType>, field: Field, expr: Expr): Null<Expr> {
		final sectionName = (cls != null ? '${cls.name}.' : "") + field.name;
		currentSection = new Section(sectionName);

		final state = getState();
		final e = (state.modOnly ? mapExprModOnly : mapExpr)(expr, new ExprMapContext());

		if(currentSection.hasEntries()) {
			files.addSectionToFile(currentSection, state.format, state.file);
			Output.addSectionToAllFiles(currentSection, state.format, state.file);
			currentSection = null;
			currentNames = [];

			// Prepend loader function to this function
			return macro {
				$i{getLoadFunctionName()}();
				@:mergeBlock $e;
			};
		}

		return null;
	}

	/**
		Processes an expression.

		Redirects constants to their data holding variable and record them.
	**/
	function mapExpr(expr: Expr, context: ExprMapContext): Expr {
		final result = processConstant(expr, context);
		return result ?? mapWithContext(expr, context, mapExpr);
	}

	/**
		Works the same as `mapExpr`, but used when `ModOnly` mode is enabled.
	**/
	function mapExprModOnly(expr: Expr, context: ExprMapContext): Expr {
		final result = switch(expr.expr) {
			case EMeta({ name: _ == Meta.Mod => true }, _): {
				processConstant(expr, context);
			}
			case _: null;
		}
		return result ?? mapWithContext(expr, context, mapExprModOnly);
	}

	/**
		Checks if the provided `Expr` is a constant that can be modified by Modifaxe.
		If so, it is added as an entry and its replacement `Expr` is returned.
		Returns `null` otherwise.
	**/
	function processConstant(expr: Expr, context: ExprMapContext, overrideName: Null<String> = null): Null<Expr> {
		return switch(expr.expr) {
			case EMeta({ name: _ == Meta.Mod => true, params: params }, innerExpr) if(params != null): {
				processModMeta(innerExpr, params, context, overrideName);
			}
			case EConst(CIdent(id)) if(id == "true" || id == "false"): {
				makeEntry(0, overrideName, id, expr, context);
			}
			case EConst(CInt(intString, _)): {
				makeEntry(1, overrideName, intString, expr, context);
			}
			case EConst(CFloat(floatString, _)): {
				makeEntry(2, overrideName, floatString, expr, context);
			}
			case EConst(CString(string, DoubleQuotes)): {
				makeEntry(3, overrideName, string, expr, context);
			}
			case _: {
				null;
			}
		}
	}

	/**
		Processes a `@:mod EXPR` expression.
	**/
	function processModMeta(innerExpr: Expr, params: Array<Expr>, context: ExprMapContext, name: Null<String>) {
		// Parse `@:mod` arguments
		var newName = null;
		var enumTypeExpr: Null<Expr> = null;
		for(p in params) {
			switch(p) {
				case { expr: EConst(CIdent(name) | CString(name, _)) }: {
					newName = name;
					break;
				}
				case macro Enum=$name: {
					enumTypeExpr = name;
				}
				case _:
			}
		}
		
		// If not an Enum, call `processConstant` normally
		if(enumTypeExpr == null) {
			return processConstant(innerExpr, context, newName);
		}

		// Try and determine `Type` from enum path expression
		final enumType: Null<Type> = #if macro try { Context.getType(dotPathExprToString(enumTypeExpr)); } catch(e) #end { null; }
		if(enumType == null) {
			return #if macro Context.error("Could not determine type.", enumTypeExpr.pos) #else innerExpr #end;
		}

		// Replace enum identifier constant or generate error
		return switch(innerExpr.expr) {
			case EConst(CIdent(ident)): {
				Output.addDataEnumLoader((enumType : Type), enumTypeExpr.pos, innerExpr, ident);
				makeEntry(4, name ?? context.generateName(), ident, innerExpr, context, enumType);
			}
			case _: {
				#if macro
				Context.error("Enum constant must just be identifier.", innerExpr.pos);
				#end
				innerExpr;
			}
		}
	}

	/**
		Converts an `Expr` of identifiers and field access into a dot-path `String`.
	**/
	function dotPathExprToString(e: Expr) {
		return switch(e.expr) {
			case EConst(CIdent(c)): c;
			case EField(e2, field, _): dotPathExprToString(e2) + "." + field;
			case EParenthesis(e): dotPathExprToString(e);
			case _: "";
		}
	}

	/**
		Adds an entry and returns its access expression.
	**/
	function makeEntry(type: Int, name: Null<String>, content: String, expr: Expr, context: ExprMapContext, enumType: Null<Type> = null) {
		if(currentSection == null) {
			throw "Cannot create entries without section.";
		}

		final name = ensureUniqueName(name ?? context.generateName(), expr.pos);
		currentNames.set(name, true);

		var complexType;
		var entryValue: EntryValue;

		switch(type) {
			case 0: {
				complexType = macro : Bool;
				entryValue = EBool(content == "true");
			}
			case 1: {
				complexType = macro : Int;
				entryValue = EInt(content);
			}
			case 2: {
				complexType = macro : Float;
				entryValue = EFloat(content);
			}
			case 3: {
				complexType = macro : String;
				entryValue = EString(content);
			}
			case 4 if(enumType != null): {
				complexType = haxe.macro.TypeTools.toComplexType(enumType) ?? macro : Dynamic;
				entryValue = EEnum(content, enumType);
			}
			case _: throw "Invalid type id.";
		}

		final entry = currentSection.addEntry(name, entryValue);
		final entryUniqueName = entry.getUniqueName();

		addDataField(entryUniqueName, complexType, expr);

		return macro $i{entryUniqueName};
	}

	function ensureUniqueName(name: String, expressionPos: Position) {
		if(currentNames.exists(name)) {
			name += "_Line" + #if macro PositionTools.toLocation(expressionPos).range.start.line #else 0 #end;
		}
		while(currentNames.exists(name)) {
			name += "_";
		}
		return name;
	}

	/**
		Adds a field to the runtime data class.
	**/
	function addDataField(name: String, complexType: ComplexType, originalExpression: Expr) {
		staticDataFields.push({
			name: name,
			access: [APublic, AStatic],
			pos: originalExpression.pos,
			kind: FVar(complexType, originalExpression)
		});
	}

	/**
		A consistent reference to the name of the static data-loader function generated
		on classes.
	**/
	static function getLoadFunctionName() {
		return "_modifaxe_loadData";
	}

	/**
		Generates the data-loader function for the class.
	**/
	public function generateLoadFunction() {
		final loadExpressions = [];
		for(formatIdent => fileList in files.generateFileList()) {
			final format = formatIdent.getFormat();
			if(format != null) {
				loadExpressions.push(format.generateLoadExpression(fileList)); // Generate loading code
			}
		}

		final loadFunctionExpr = macro {
			static var i = 0;
			if(i != Modifaxe.refreshCount) {
				i = Modifaxe.refreshCount;
			} else {
				return;
			}

			$b{loadExpressions};
		}

		staticDataFields.push({
			name: getLoadFunctionName(),
			access: [AStatic],
			pos: loadFunctionExpr.pos,
			kind: FFun({
				args: [],
				expr: loadFunctionExpr
			})
		});
	}

	/**
		Returns a list of `Field`s to be added to the class that had this `Builder` 
		generated in their `@:build` macro.
	**/
	public function getAdditionalFields(): Array<Field> {
		return staticDataFields;
	}
}

#end
