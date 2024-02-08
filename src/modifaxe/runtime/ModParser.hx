package modifaxe.runtime;

using StringTools;

/**
	A `.modhx` parser.

	The goal is highest-performance and minimal Haxe API usage.

	This should only use `fastCodeAt` on `String`, AND avoid all concatenation
	(except using `substring` to generate the return `String` of `nextEntry`).
**/
class ModParser {
	var pos: Int;
	var line: Int;
	var lineStart: Int;
	var content: String;

	#if !modifaxe_parser_no_map_cache
	/**
		Used with a parser set up through `fromEntryCount` to set where entries
		will be retrieved from the cache.
	**/
	var entriesCachePos: Int = 0;

	/**
		Stores all the parsed entries.
	**/
	var entriesCache: Array<String> = [];
	#end

	public function new(filePath: String) {
		pos = 0;
		line = 0;
		lineStart = 0;
		content = loadString(filePath);
	}

	/**
		Creates an instance of `ModParser` starting from a specific entry.

		`startEntryCount` should be the number of entries ignored before parsing begins.
	**/
	public static function fromEntryCount(filePath: String, startEntryCount: Int) {
		#if modifaxe_parser_no_map_cache

		// If not using a cache, make a fresh `ModParser` and find the starting entry
		final result = new ModParser(filePath);
		for(i in 0...startEntryCount) {
			result.nextEntry();
		}
		return result;

		#else

		// Haxe 4.3.2 required for `static var _: Map`
		#if (haxe < version("4.3.2"))
		#error "Haxe 4.3.2+ required for local static Map. (See #11193, #11301)";
		#end

		// Clear cache if `Modifaxe` has been reloaded
		static var cache: Map<String, ModParser> = [];
		static var i = 0;
		if(i != Modifaxe.refreshCount) {
			i = Modifaxe.refreshCount;
			cache = [];
		}

		// Generate `.modhx` parser if one for this file doesn't exist
		var result = cache.get(filePath);
		if(result == null) {
			result = new ModParser(filePath); 
			cache.set(filePath, result);
		}

		// Go to starting entry
		result.goToEntry(startEntryCount);
		return result;

		#end
	}

	#if !modifaxe_parser_no_map_cache

	/**
		Places the position of the parser directly after the number 
	**/
	public function goToEntry(entryIndex: Int) {
		// Parse entries until `entryIndex`.
		while(entryIndex >= entriesCache.length) {
			final e = nextEntry();
			if(e == null) {
				// TODO: Too many entries expected? Should this generate error??
				break;
			}
		}

		entriesCachePos = entryIndex;
	}

	#end

	/**
		Loads the `String` content from a text file at `filePath`.
		Can be dynamically overwritten with custom file-loading code.
	**/
	public #if modiflaxe_no_dynamic_functions dynamic #end function loadString(filePath: String) {
		return sys.io.File.getContent(filePath);
	}

	#if !modifaxe_parser_no_error_check
	/**
		Reports an parsing error.
		Can be dynamically overwritten with custom error-reporting code.
	**/
	public #if modiflaxe_no_dynamic_functions dynamic #end function onError(error: ModParserError, skipToNextLine: Bool) {
		// Print
		final lineNumberStr = Std.string(line + 1);
		var line1 = "".lpad(" ", lineNumberStr.length + 1) + " |";
		var line2 = ' $lineNumberStr | ${content.substring(lineStart, getEndOfCurrentLine())}';
		var line3 = '$line1${"".lpad(" ", pos - lineStart + 1)}^ ${error.getMessage()}';
		Sys.println('[Modifaxe Parse Error]\n$line1\n$line2\n$line3');

		// Skip to next line
		if(skipToNextLine) {
			pos = getEndOfCurrentLine();
		}
	}
	#end

	/**
		Returns the index of the next new line (\n) or end of file.
	**/
	function getEndOfCurrentLine() {
		var result = pos;
		final len = content.length;
		while(result < len) {
			if(content.fastCodeAt(result) == 10) {
				break;
			}
			result++;
		}
		return result;
	}

	/**
		Gets the next value entry as a `String`.
	**/
	public function nextEntry(): Null<String> {
		#if !modifaxe_parser_no_map_cache
		if(entriesCachePos < entriesCache.length) {
			return entriesCache[entriesCachePos++];
		}
		#end

		final result = nextEntryImpl();

		#if !modifaxe_parser_no_map_cache
		if(result != null) {
			entriesCache.push(result);
			entriesCachePos++;
		}
		#end

		return result;
	}

	/**
		The implementation for `nextEntry`.
	**/
	function nextEntryImpl(): Null<String> {
		final len = content.length;

		var start = pos;
		var end = pos;

		while(pos < len) {
			final c = content.fastCodeAt(pos);
			switch(c) {
				// \n (new line)
				case 10: {
					start = end = pos;
					pos++;
					line++;
					lineStart = pos;
				}

				// whitespace (Based on `StringTools.isSpace`)
				case 9 | 11 | 12 | 13 | 32: {
					start = pos;
					end = pos;
					pos++;
				}

				// # (pound sign)
				case 35: {
					if(goToNewLine()) {
						// skip rest of loop so `pos` isn't incremented
						pos++;
						continue;
					} else {
						// break since end was hit
						break;
					}
				}

				// [ (open square bracket)
				case 91: {
					#if !modifaxe_parser_no_error_check
					if(pos - lineStart > 0) {
						onError(SectionShouldBeStartOfLine, false);
					}
					#end

					// move past [
					pos++;

					// move past identifier
					expectIdentifier(true);

					// move past ]
					expectChar(93);
				}

				// b, i, f, s, or e for the type
				case 98 | 105 | 102 | 115 | 101: {
					#if !modifaxe_parser_no_error_check
					if(pos - lineStart > 0) {
						onError(EntryShouldBeStartOfLine, false);
					}
					#end

					final type = switch(c) {
						case 98: 0; // bool
						case 105: 1; // int
						case 102: 2; // float
						case 115: 3; // string
						case 101: 4; // enum
						case _: 0; // impossible
					}

					// move past type char
					pos++;

					// move past .
					expectChar(46);

					// move past identifier
					expectIdentifier(false);

					// move past :
					expectChar(58);

					// skip spaces if they exist
					while(content.fastCodeAt(pos) == 32) {
						pos++;
					}

					// start found
					start = pos;

					switch(type) {
						case 0: expectBool();
						case 1: expectInt();
						case 2: expectFloat();
						case 3: return expectAndGetString(); // special case, String type returns itself
						case 4: expectIdentifier(false);
					}

					end = pos;

					return content.substring(start, end);
				}

				case _: {
					#if !modifaxe_parser_no_error_check
					onError(UnexpectedChar(c), true);
					#end
					pos++;
				}
			}
		}

		return null;
	}

	/**
		Calls `getValueText` and parses it as a `Bool`.
	**/
	public function nextBool(defaultValue: Bool): Bool {
		final line = nextEntry();
		if(line != null) {
			return line == "true";
		}
		return defaultValue;
	}

	/**
		Calls `getValueText` and parses it as an `Int`.
	**/
	public function nextInt(defaultValue: Int): Int {
		final line = nextEntry();
		if(line != null) {
			return Std.parseInt(line) ?? defaultValue;
		}
		return defaultValue;
	}

	/**
		Calls `getValueText` and parses it as a `Float`.
	**/
	public function nextFloat(defaultValue: Float): Float {
		final line = nextEntry();
		if(line != null) {
			return Std.parseFloat(line);
		}
		return defaultValue;
	}

	/**
		Returns the value of `getValueText`.
		This function doesn't do anything at the moment; it exists for consistency.
	**/
	public function nextString(defaultValue: String) {
		final line = nextEntry();
		return line;
	}

	/**
		Returns the value of `getValueText`.
		This function doesn't do anything at the moment; it exists for consistency.
	**/
	public function nextEnumIdentifier(defaultValue: String) {
		final line = nextEntry();
		return line;
	}

	/**
		Moves `pos` to the next "\n".

		Returns `true` if successful.
		Returns `false` if there are no "\n" for the rest of the string.
	**/
	function goToNewLine() {
		final len = content.length;

		while(pos < len) {
			switch(content.fastCodeAt(pos)) {
				case 10: {
					return true;
				}
				case _:
			}
			pos++;
		}

		return false;
	}

	/**
		Moves `pos` to the end of the next identifier.

		`pos` should be on the first character of the identifier before calling.
		Returns `false` if the current character is not a valid start for an identifier.

		An identifier is a group of alphanumeric and underscore characters following
		Haxe's identifier rules.

		If `allowDot` is `true`, "." is also accepted in the identifier (section identifiers can contain ".").
	**/
	function nextIdentifier(allowDot: Bool) {
		final len = content.length;

		// Check that first character is letter
		switch(content.fastCodeAt(pos)) {
			case c if((c >= 65 && c <= 90) || (c >= 97 && c <= 122)): {
				pos++;
			}
			case _: {
				return false;
			}
		}

		while(pos < len) {
			final c = content.fastCodeAt(pos);
			// allow A-Z, a-z, 0-9, _, and . (if `allowDot` is true)
			if((c >= 65 && c <= 90) || (c >= 97 && c <= 122) || (c >= 48 && c <= 57) || c == 95 || (allowDot && c == 46)) {
				pos++;
			} else {
				break; // end once hit non-identifier character
			}
		}

		return true;
	}

	/**
		Checks if the current character is the `char` char code.

		If it is, increment `pos`.
		If not, return `false`.
	**/
	inline function expectChar(char: Int) {
		if(content.fastCodeAt(pos) == char) {
			pos++;
			return true;
		}
		#if !modifaxe_parser_no_error_check
		onError(ExpectedChar(char), true);
		#end
		return false;
	}

	/**
		Checks and skips the current identifier.

		If it's a valid identifier, `pos` is set to the end.
		If not, return `false`.
	**/
	inline function expectIdentifier(allowDot: Bool) {
		if(!nextIdentifier(allowDot)) {
			#if !modifaxe_parser_no_error_check
			onError(ExpectedIdentifier, true);
			#end
		}
	}

	/**
		Expects either `true` or `false`.
		NOTE: This function goes hard af.
	**/
	function expectBool() {
		switch(content.fastCodeAt(pos)) {
			case 116: { // t
				pos++;
				expectChar(114); // r
				expectChar(117); // u
				expectChar(101); // e
			}
			case 102: { // f
				pos++;
				expectChar(97); // a
				expectChar(108); // l
				expectChar(115); // s
				expectChar(101); // e
			}
			case _: {
				#if !modifaxe_parser_no_error_check
				onError(ExpectedBool, true);
				#end
			}
		}
	}

	/**
		Parse the next content under the assumption it is an `Int`.
		Generate an error if anything unexpected occurs.
	**/
	function expectInt() {
		final len = content.length;

		// Check if first character is - (minus)
		if(content.fastCodeAt(pos) == 45) {
			pos++;
		}

		// Check for at least one number
		final c = content.fastCodeAt(pos);
		if(c >= 48 && c <= 57) {
			pos++;
		} else {
			#if !modifaxe_parser_no_error_check
			onError(ExpectedDigit, true);
			#end
		}

		while(pos < len) {
			final c = content.fastCodeAt(pos);
			// allow 0-9
			if(c >= 48 && c <= 57) {
				pos++;
			} else {
				break; // end once hit non-number character
			}
		}
	}

	/**
		Parse the next content under the assumption it is an `Float`.
		Generate an error if anything unexpected occurs.
	**/
	function expectFloat() {
		// Check if first character is - (minus)
		if(content.fastCodeAt(pos) == 45) {
			pos++;
		}

		// Check for at least one number
		final c = content.fastCodeAt(pos);
		if(c >= 48 && c <= 57) {
			pos++;
		} else {
			#if !modifaxe_parser_no_error_check
			onError(ExpectedDigit, true);
			#end
		}

		final len = content.length;
		var processedDot = false;
		while(pos < len) {
			final c = content.fastCodeAt(pos);

			// allow 0-9
			if(c >= 48 && c <= 57) {
				pos++;
			} else if(!processedDot && c == 46) {
				pos++;
				processedDot = true;
			} else {
				break; // end once hit non-number character
			}
		}
	}

	/**
		Parse the next content under the assumption it is an `String`.
		If parsed successfully, the `String` is returned.
	**/
	function expectAndGetString() {
		// move past "
		expectChar(34);

		final len = content.length;
		final result = #if modifaxe_parser_use_string_concat "" #else new StringBuf() #end;
		var start = pos;

		while(pos < len) {
			final c = content.fastCodeAt(pos);

			switch(c) {
				case 92 | 34: {
					if(pos > start) {
						#if modifaxe_parser_use_string_concat
						result += content.substring(start, pos);
						#else
						result.add(content.substring(start, pos));
						#end
					}

					if(c == 92 && (pos + 1) < len) {
						// backslash \
						final newChar = switch(content.fastCodeAt(pos + 1)) {
							case 34: "\"";
							case 92: "\\";
							case 110: "\n";
							case 116: "\t";
							case _: {
								#if !modifaxe_parser_no_error_check
								onError(UnsupportedEscapeSequence, false);
								#end
								"";
							}
						}

						#if modifaxe_parser_use_string_concat
						result += newChar;
						#else
						result.add(newChar);
						#end

						pos++;
						start = pos + 1; // increment `start` one more, since `pos++` at end of loop
					} else {
						// double-quote "
						pos++;
						break;
					}
				}
			}

			pos++;
		}

		return result.toString();
	}
}
