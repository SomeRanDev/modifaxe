package modifaxe;

#if (macro || modifaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;

import modifaxe.builder.Builder;
import modifaxe.config.Meta;

function build() {
	final cls = #if macro Context.getLocalClass() #else null #end;
	final cls = cls != null ? cls.get() : null;
	final processAll = cls?.meta.has(Meta.Modifaxe) ?? false;

	final fields: Array<Field> = #if macro Context.getBuildFields() #else [] #end;

	final builder = new Builder();

	for(f in fields) {
		var skip = !processAll;
		if(skip && f.meta != null) {
			for(m in f.meta) {
				if(m.name == Meta.Modifaxe) {
					skip = false;
					break;
				}
			}
		}
		if(skip) {
			continue;
		}

		switch(f.kind) {
			case FFun(func) if(func.expr != null): {
				final newExpr = builder.buildFunctionExpr(cls, f, func.expr);
				if(newExpr != null) {
					func.expr = newExpr;
				}
			}
			case _:
		}
	}

	builder.onFinishedBuilding();

	return fields;
}

#end
