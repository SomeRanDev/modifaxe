<img src="https://i.imgur.com/oZkCZ2C.png" alt="I made a reflaxe logo thingy look at it LOOK AT IT" width="400"/>

[![Test Workflow](https://github.com/SomeRanDev/reflaxe/actions/workflows/test.yml/badge.svg)](https://github.com/SomeRanDev/reflaxe/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<a href="https://discord.com/channels/162395145352904705/1052688097592225904"><img src="https://discordapp.com/api/guilds/162395145352904705/widget.png?style=shield" alt="Reflaxe Thread"/></a>

*A tool for modifying hardcoded values in your post-build Haxe application.*

Change a value -> recompile -> test -> repeat. Every programmer has experienced this loop before; it's very tempting to "guess and check" when it comes to visually designing something with code. This library seeks to aliviate the tedious "recompile" step by allowing hardcoded values from your code to be modified AFTER compiling.

If you're reading this, you're here WAAAAAAAAAAAAAY too early. Nothing is implemented yet.

&nbsp;
&nbsp;

## Table of Contents

| Topic | Description |
| --- | --- |
| [Installation](#automatic-installation) | How to install this library into your project. |

&nbsp;
&nbsp;
&nbsp;

## Installation
First install Modifaxe using one of the commands below:
```hxml
# install haxelib release (may not exist atm!!)
haxelib install modifaxe

# install nightly (recommended!)
haxelib git modifaxe https://github.com/SomeRanDev/modifaxe.git
```

Next add the library to your .hxml or compile command:
```
-lib modifaxe
```

Add the `@:modifaxe` metadata to a class or function:
```haxe
@:modifaxe
function getWindowSize() {
	return 800;
}
```

Compile your Haxe project to a `sys` target with file-system access.
Modify the value(s) in the generated `values.modhx` file:
```
Main.getWindowSize:
	i.return=800
```

&nbsp;
&nbsp;
&nbsp;

## .modhx Format
The `.modhx` is a text-based file format designed specifically for this project. It is designed to be both human-readable and easily parsable.

Lines that (excluding whitespace) start with pound sign (#) are comments and are ignored during parsing:
```
# This is a comment.
	# This is also a comment.
Something # Invalid comment
```

All content starts with a unique identifier followed by a colon. A list of values should follow with the `\t<type>.<name>=<value>` format:
```
My.Unique.ID:
	b.trueOrFalse=true
	i.myNum=123
	f.floatNum=6.9
	s.string="Insert valid Haxe string here.
They can be multiline."
```

Please note the order of value entries MATTERS. The Haxe code for parsing the custom-made `.modhx` is hardcoded to expect the values in the exact order. The section and value identifiers exist to help locate values to manually modify.

There are four types supported:
 * `b` is a boolean.
 * `i` is an integer.
 * `f` is a float.
 * `s` is a string.

The `name` must be a valid Haxe variable name.

The `value` must be a valid constant Haxe expression of the specified type.

&nbsp;
&nbsp;
&nbsp;
