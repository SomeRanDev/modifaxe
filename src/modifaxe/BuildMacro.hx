package modifaxe;

#if (macro || modifaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;

import modifaxe.builder.Builder;
import modifaxe.config.Meta;

/**
	The `@:build` macro function called on all types.
**/
function build() {
	// ClassType
	final cls = #if macro Context.getLocalClass() #else null #end;
	final cls = cls != null ? cls.get() : null;

	// Array<Field>
	final fields: Array<Field> = #if macro Context.getBuildFields() #else [] #end;

	// Create `Builder` if metadata arguments are supplied
	var builder = null;
	function pushArgs(args: Null<Array<Expr>>) {
		if(builder == null) builder = new Builder();
		builder.setArguments(args ?? []);
	}
	function popArgs() builder.popArguments();

	// Check for class `@:modifaxe` args
	final processAll = if(cls != null) {
		final metaEntries: Array<MetadataEntry> = cls.meta.extract(Meta.Modifaxe);
		for(entry in metaEntries) {
			pushArgs(entry.params);
		}
		metaEntries.length > 0;
	} else {
		false;
	}

	// Process fields
	for(f in fields) {
		// Check for `@:modifaxe`
		var hasMeta = false;
		if(f.meta != null) {
			for(m in f.meta) {
				if(m.name == Meta.Modifaxe) {
					pushArgs(m.params);
					hasMeta = true;
					break;
				}
			}
		}

		// Skip if no `@:modifaxe` on function or class
		if(!hasMeta && !processAll) {
			continue;
		}

		// Process the function body
		switch(f.kind) {
			case FFun(func) if(func.expr != null): {
				final newExpr = builder.buildFunctionExpr(cls, f, func.expr);
				if(newExpr != null) {
					func.expr = newExpr;
				}
			}
			case _:
		}

		// Pop function-specific state
		if(hasMeta) {
			popArgs();
		}
	}

	return fields;
}

#end
