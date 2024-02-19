<img src="https://github.com/SomeRanDev/modifaxe/blob/main/.github/logo.png" alt="WOOO been a while since I made a logo." width="400"/>

[![Test Workflow](https://github.com/SomeRanDev/modifaxe/actions/workflows/Test_DevEnv.yml/badge.svg)](https://github.com/SomeRanDev/modifaxe/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<a href="https://discord.com/channels/162395145352904705/1202862068961910794/"><img src="https://discordapp.com/api/guilds/162395145352904705/widget.png?style=shield" alt="Modifaxe Thread"/></a>

*A tool for modifying hardcoded values in your post-build Haxe application.*

Change a value -> recompile -> test -> repeat. Every programmer has experienced this loop before; it's very tempting to "guess and check" when it comes to visually designing something with code. This library seeks to aliviate the tedious "recompile" step by allowing hardcoded values from your code to be modified AFTER compiling.

&nbsp;
&nbsp;

## Table of Contents

| Topic | Description |
| --- | --- |
| [Installation](#installation) | How to install this library into your project.       |
| [Reloading](#reloading)       | How to reload values at runtime.                     |
| [Metadata Configuration](#metadata-configuration) | How to configure the metadata.   |
| [Define Configuration](#defines) | A list of defines to set the library preferences. |
| [.modhx Format](#modhx-format) | An explanation of the `.modhx` format.              |
| [How it Works](#how-it-works) | How Modifaxe transforms your project to function.    |

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
```haxe
[Main.getWindowSize]
i.return: 800
```

Aaand run!

&nbsp;
&nbsp;
&nbsp;

## Reloading

To reload the values at runtime, `Modifaxe.reload` can be called.

This can be used to generate your own makeshift hot-reloading system, like:
```haxe
// Update function in some random game engine...
function update() {
	if(isDebugReloadKeyPressed()) {
		Modifaxe.reload();
	}
}
```

&nbsp;
&nbsp;
&nbsp;

## Metadata Configuration

The `@:mod` metadata can be placed on expressions to specify their name.
```haxe
@:modifaxe
function getWindowSize() {
	return @:mod("my_num") 800;
}
```
```haxe
[Main.getWindowSize]
i.my_num: 800
```

To only use constants that have the `@:mod` metadata, the `ModOnly` argument can be used:
```haxe
@:modifaxe(ModOnly)
function getWindowSize() {
	return @:mod("my_num") 800 + 100;
}
```

&nbsp;

The `@:mod` metadata must also be used to allow for enum configuration. Use the `Enum` argument to set the path to the enum type.

```haxe
enum Color {
	Red;
	Green;
	Blue;
}

@:modifaxe
function colorWindow() {
	window.setColor(@:mod(Enum=Main.Color) Red);
}
```
```haxe
[Main.colorWindow]
i.Argument0: Red
```

&nbsp;

The `File` argument can be used to specify the filename the entries under a metadata will be placed in. Multiple data files can be generated/loaded from this way:
```haxe
// Generates data1.modhx file containing one entry
@:modifaxe(File="data1")
function getWindowWidth() { return 800; }

// Generates data2.modhx file that also contains this one entry
@:modifaxe(File="data2")
function getWindowHeight() { return 400; }
```

&nbsp;

The `Format` argument can be used to set the format of the file entries are placed into. By default, Modifaxe only has one format supported, `modhx`. However, it is possible for other libraries to add their own formats. Check out the [Modifaxe/JSON](https://github.com/SomeRanDev/modifaxe.JSON) library to see an example of this!

If Modifaxe/JSON is installed, a `.json` format can be used like so:
```haxe
// Generates and loads the data in a modifiable .json file
@:modifaxe(Format=Json)
function getWindowWidth() {
	return 800;
}
```

&nbsp;
&nbsp;
&nbsp;

## Defines

To specify a specific path this library works on (instead of using a global `@:build` macro which could be slower), the `-D modifaxe_path_filter` define can be used:
```hxml
-D modifaxe_path_filter=my_package
```

To set the default filename for the generated data file, the `-D modifaxe_default_file_path` define can be used (the extension is added automatically):
```hxml
-D modifaxe_default_file_path=my_data_file
```

You can view a list of all the `-D` defines you can use to configure the library [here](https://github.com/SomeRanDev/modifaxe/blob/main/src/modifaxe/config/Define.hx).

&nbsp;
&nbsp;
&nbsp;

## .modhx Format
The `.modhx` is a text-based file format designed specifically for this project. It is designed to be both human-readable and easily parsable.

&nbsp;

### Comments
Content after a pound sign (#) is a comment and is ignored during parsing:
```python
# This is a comment.
	# This is also a comment.
Something # Comment after content
```

&nbsp;

### Sections and Values
Entries are separated into sections. A section is a unique identifier followed by a colon.

A list of values should follow with the `<type>.<name>: <value>` format:
```haxe
[My.Unique.ID]
b.trueOrFalse=true
i.myNum=123
f.floatNum=6.9
s.string="Insert valid Haxe string here.
They can be multiline."
```

Please note the order of value entries MATTERS. The Haxe code for parsing the custom-made `.modhx` is hardcoded to expect the values in their generated order. The section and value identifiers exist to help humans locate values to modify.

&nbsp;

### Value Declaration Options

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

## How it Works

Each class that uses `@:modifaxe` is given a static function named `_modifaxe_loadData` and a static var for each constant that can be modified.

At the start of any function with a changeable constant, `_modifaxe_loadData` checks its internal counter to see if it matches with the `Modifaxe` counter. If it doesn't, it runs the procedrually-generated loading code for all the static variables. Otherwise, nothing happens.

```haxe
// Before
@:modifaxe
class MyClass {
	public function doSomething() {
		trace(123);
	}
}
```
```haxe
// After
class MyClass {
	static var MyClass_doSomething_Argument0 = 123;

	static function _modifaxe_loadData() {
		static var count = 0;
		if(count != Modifaxe.refreshCount) count = Modifaxe.refreshCount;
		else return;

		final parser = modifaxe.runtime.ModParser.fromEntryCount("data.modhx", 0);
		MyClass_doSomething_Argument0 = parser.nextInt(123);
	}

	public function doSomething() {
		_modifaxe_loadData();
		trace(MyClass_doSomething_Argument0);
	}
}
```
