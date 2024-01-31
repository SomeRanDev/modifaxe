package modifaxe;

#if (macro || modifaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;

import modifaxe.builder.Builder;
import modifaxe.config.Meta;

function build() {
	final cls = #if macro Context.getLocalClass() #else null #end;
	final processAll = cls != null && cls.get().meta.has(Meta.Modifaxe);

	final fields: Array<Field> = #if macro Context.getBuildFields() #else [] #end;

	final builder = new Builder();

	for(f in fields) {
		var skip = !processAll;
		if(skip) {
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
				final newExpr = builder.buildFunctionExpr(f.name, func.expr);
				if(newExpr != null) {
					func.expr = newExpr;
				}
			}
			case _:
		}
	}

	if(builder.hasSections()) {
		trace(builder.generateModHxContent().toString());
	}

	return fields;
}

#end
