package modifaxe.tools;

#if (macro || modifaxe_runtime)

import haxe.macro.Expr;
import haxe.macro.ExprTools;

/**
	A class used to help track the expression mapping history so a descriptive name can be
	generated for the constant value entry.
**/
class ExprMapContext {
	var nameStack: Array<String> = [];
	var varNameStack: Array<String> = [];
	var funcNameStack: Array<String> = [];

	public function new() {
	}

	public function generateName() {
		if(nameStack.length > 0) {
			return nameStack[nameStack.length - 1];
		}

		return "value";
	}

	public function named(name: String) {
		nameStack.push(name);
		return this;
	}

	public function popName() {
		nameStack.pop();
	}

	public function pushVar(name: String) {
		varNameStack.push(name);
	}

	public function popVar() {
		varNameStack.pop();
	}

	public function pushFunction(name: String) {
		funcNameStack.push(name);
	}

	public function popFunction() {
		funcNameStack.pop();
	}
}

/**
	Used internally in `mapWithContext`.
**/
private inline function opt(e: Null<Expr>, role: Null<String>, f: (Expr, String) -> Expr): Expr {
	return e == null ? null : f(e, role);
}

/**
	Used internally in `mapWithContext`.
**/
private inline function arrMap(el: Array<Expr>, f: (Expr, Int) -> Expr): Array<Expr> {
	var ret = [];
	for (i in 0...el.length) ret.push(f(el[i], i));
	return ret;
}

private function getBinopName(op: Binop, isRight: Bool) {
	final opBaseName = Std.string(op).substring(2);

	if(isRight) {
		final result = switch(opBaseName) {
			case "Mult": "MultipliedBy";
			case "Div": "DividedBy";
			case "Eq": "EqualTo";
			case "NotEq": "NotEqualTo";
			case "Gte": "GreaterThanOrEqualTo";
			case "Lte": "LessThanOrEqualTo";
			case _: null;
		}

		if(result != null) return result;
	}

	final base = switch(opBaseName) {
		

		case "Add": "Addition";
		case "Sub": "Subtraction";
		case "Mult": "Multiplication";
		case "Div": "Division";
		case "Eq": "Equals";
		case "NotEq": "NotEquals";
		case "Gt": "GreaterThan";
		case "Gte": "GreaterThanOrEquals";
		case "Lt": "LessThen";
		case "Lte": "LessThanOrEquals";
		case n: n;
	}

	return (isRight ? "RightOf" : "LeftOf") + base;
}
private inline function getUnopName(op: Unop) {
	return Std.string(op).substring(2);
}

/**
	An alternative version of `ExprTools.map` that passes around an `ExprMapContext` and names each `ExprDef`.
**/
function mapWithContext(e: Expr, context: ExprMapContext, callback: (Expr, ExprMapContext) -> Expr): Expr {
	function f(_e, role: Null<String>) {
		if(role == null) return callback(_e, context);

		final result = callback(_e, context.named(role));
		context.popName();
		return result;
	}

	return {
		pos: e.pos,
		expr: switch (e.expr) {
			case EConst(_): e.expr;
			case EArray(e1, e2): EArray(f(e1, "ArrayAccessed"), f(e2, "ArrayAccess"));
			case EBinop(op, e1, e2): EBinop(op, f(e1, getBinopName(op, false)), f(e2, getBinopName(op, true)));
			case EField(e, field, kind): EField(f(e, "fieldAccessed"), field, kind);
			case EParenthesis(e): EParenthesis(f(e, null));
			case EObjectDecl(fields):
				var ret = [];
				for (field in fields)
					ret.push({field: field.field, expr: f(field.expr, "ObjectField_" + field.field), quotes: field.quotes});
				EObjectDecl(ret);
			case EArrayDecl(el): EArrayDecl(arrMap(el, (e, i) -> f(e, "ArrayElement" + i)));
			case ECall(e, params): ECall(f(e, "Called"), arrMap(params, (e, i) -> f(e, "CallArgument" + i)));
			case ENew(tp, params): ENew(tp, arrMap(params, (e, i) -> f(e, "ConstructorArgument" + i)));
			case EUnop(op, postFix, e): EUnop(op, postFix, f(e, Std.string(op)));
			case EVars(vars):
				var ret = [];
				for (v in vars) {
					context.pushVar(v.name);
					var v2:Var = {name: v.name, type: v.type, expr: opt(v.expr, null, f)};
					if (v.isFinal != null)
						v2.isFinal = v.isFinal;
					ret.push(v2);
					context.popVar();
				}
				EVars(ret);
			case EBlock(el): EBlock(arrMap(el, (e, i) -> f(e, null)));
			case EFor(it, expr): EFor(f(it, "ForIterator"), f(expr, "ForExpr"));
			case EIf(econd, eif, eelse): EIf(f(econd, "IfCondition"), f(eif, "Elseif"), opt(eelse, "Else", f));
			case EWhile(econd, e, normalWhile): EWhile(f(econd, "WhileCondition"), f(e, "WhileBlock"), normalWhile);
			case EReturn(e): EReturn(opt(e, "Returned", f));
			case EUntyped(e): EUntyped(f(e, null));
			case EThrow(e): EThrow(f(e, "Thrown"));
			case ECast(e, t): ECast(f(e, "Casted"), t);
			case EIs(e, t): EIs(f(e, null), t);
			case EDisplay(e, dk): EDisplay(f(e, null), dk);
			case ETernary(econd, eif, eelse): ETernary(f(econd, "TernaryCondition"), f(eif, "TernaryIfTrue"), f(eelse, "TernaryIfFalse"));
			case ECheckType(e, t): ECheckType(f(e, null), t);
			case EContinue, EBreak:
				e.expr;
			case ETry(e, catches):
				var ret = [];
				var index = 0;
				for (c in catches)
					ret.push({name: c.name, type: c.type, expr: f(c.expr, "Catch" + (index++))});
				ETry(f(e, "TryBlock"), ret);
			case ESwitch(e, cases, edef):
				var ret = [];
				var index = 0;
				for (c in cases) {
					ret.push({expr: opt(c.expr, "Case" + index, f), guard: opt(c.guard, "CaseGuard" + index, f), values: arrMap(c.values, (e, i) -> f(e, "Case" + index + "Pattern" + i))});
					index++;
				}
				ESwitch(f(e, "SwitchValue"), ret, edef == null || edef.expr == null ? edef : f(edef, "SwitchDefault"));
			case EFunction(kind, func):
				var ret = [];
				var index = 0;
				for (arg in func.args) {
					ret.push({
						name: arg.name,
						opt: arg.opt,
						type: arg.type,
						value: opt(arg.value, "FuncArg" + (index++) + "Default", f)
					});
				}
				EFunction(kind, {
					args: ret,
					ret: func.ret,
					params: func.params,
					expr: f(func.expr, null)
				});
			case EMeta(m, e): EMeta(m, f(e, null));
		}
	};
}

#end
