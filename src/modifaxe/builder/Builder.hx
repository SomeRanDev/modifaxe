package modifaxe.builder;

#if (macro || modifaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import modifaxe.builder.File;
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
	This processes the AST and records the required entries for `.modhx`.

	An instance of `Builder` is created for each `@:build` macro used to process a class.
**/
class Builder {
	//~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Statics ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~\\

	// /**
	// 	A list of `Builder` instances that have content.
	// **/
	// static var builders: Array<Builder> = [];

	/**
		Generates the content for the `.modhx` file.
		Must be called after all @:build macros have executed.
	**/
	// public static function generateModHxContent(): String {
	// 	final buf = new StringBuf();

	// 	for(builder in builders) {
	// 		buf.add(builder.generateModHxSections());
	// 		buf.addChar(10);
	// 	}

	// 	return buf.toString();
	// }

	//~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Instance ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~\\

	var currentEntries: Array<Entry> = [];
	var currentSection: Null<Section> = null;
	//var files: Array<File> = [];

	var state: Array<ModifaxeState> = [];

	var index = 0;

	public function new() {
	}

	/**
		Call at the end of the `Builder`'s scope.
		Adds the `Builder` to the global list if it has any entries.
	**/
	public function onFinishedBuilding() {
		// if(hasFiles()) {
		// 	builders.push(this);
		// }
	}

	// /**
	// 	Returns `true` if there is at least one section to be generated.
	// **/
	// public function hasFiles() {
	// 	return files.length > 0;
	// }

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
					newState.format = formatIdent != null && formatIdent.length == 0 ? null : formatIdent;
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
			Output.addSectionToFile(currentSection, state.format, state.file);
			currentSection = null;
			return e;
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
				var newName = null;
				for(p in params) {
					switch(p.expr) {
						case EConst(CIdent(name) | CString(name, _)): {
							newName = name;
							break;
						}
						case _:
					}
				}
				processConstant(innerExpr, context, newName);
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
		Adds an entry and returns its access expression.
	**/
	function makeEntry(type: Int, name: Null<String>, content: String, expr: Expr, context: ExprMapContext) {
		if(currentSection == null) {
			throw "Cannot create entries without section.";
		}

		final name = name ?? context.generateName();

		var complexType = null;
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
			case _: throw "Invalid type id.";
		}

		final entry = currentSection.addEntry(name, entryValue);
		final entryUniqueName = entry.getUniqueName();

		addDataField(entry.getUniqueName(), complexType, expr);

		return macro ModifaxeData.$entryUniqueName;
	}

	// function addEntry(entry: Entry) {
	// 	Output.addLoadExpression(entry);
	// 	currentEntries.push(entry);
	// 	return entry;
	// }

	function addDataField(name: String, complexType: ComplexType, originalExpression: Expr) {
		Output.addDataField({
			name: name,
			access: [APublic, AStatic],
			pos: originalExpression.pos,
			kind: FVar(complexType, originalExpression)
		});
	}

	/**
		Generates this builder's `.modhx` content using its accumulated sections.
	**/
	// public function generateModHxSections(): StringBuf {
	// 	final buf = new StringBuf();

	// 	for(f in files) {
	// 		for(section in @:privateAccess f.sections) {
	// 			buf.add(section.generateModHxSection());
	// 			buf.addChar(10);
	// 		}
	// 	}

	// 	return buf;
	// }
}

#end
