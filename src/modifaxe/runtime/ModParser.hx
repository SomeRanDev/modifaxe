package modifaxe.runtime;

using StringTools;

/**
	A `.modhx` parser.

	The goal is highest-performance and minimal Haxe API usage.

	This should only use `fastCodeAt` on `String`, AND avoid all concatenation
	(except using `substring` to generate the return `String` of `nextValueText`).
**/
class ModParser {
	var pos: Int;
	var line: Int;
	var lineStart: Int;
	var content: String;

	public function new(filePath: String) {
		pos = 0;
		line = 0;
		lineStart = 0;
		content = loadString(filePath);
	}

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
	public #if modiflaxe_no_dynamic_functions dynamic #end function onError(error: ModParserError) {
		final lineNumberStr = Std.string(line + 1);
		var line1 = "".lpad(" ", lineNumberStr.length + 1) + " |";
		var line2 = ' $lineNumberStr | ${content.substring(lineStart + 1, getEndOfCurrentLine())}';
		var line3 = '$line1${"".lpad(" ", pos - lineStart)}^ ${error.getMessage()}';
		Sys.println('[Modifaxe Parse Error]\n$line1\n$line2\n$line3');
	}
	#end

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
	public function nextValueText(): Null<String> {
		final len = content.length;

		var start = pos;
		var end = pos;
		var hasStarted = false;

		while(pos < len) {
			final c = content.fastCodeAt(pos);
			switch(c) {
				// \n (new line)
				case 10: {
					start = end = pos;
					line++;
					lineStart = pos;
				}

				// whitespace (Based on `StringTools.isSpace`)
				case 9 | 11 | 12 | 13 | 32: {
					if(!hasStarted) {
						start = pos;
						end = pos;
					}
				}

				// # (pound sign)
				case 35: {
					if(goToNewLine()) {
						// skip rest of loop so `pos` isn't incremented
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
						onError(SectionShouldBeStartOfLine);
					}
					#end

					// move past [
					pos++;

					// move past identifier
					expectIdentifier(true);

					// move past ]
					expectChar(93);
				}

				// b, i, f, or s for the type
				case 98 | 105 | 102 | 115: {
					final type = switch(c) {
						case 98: 0; // bool
						case 105: 1; // int
						case 102: 2; // float
						case 115: 3; // string
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
						case 3: expectString();
					}

					end = pos;

					return content.substring(start, end);
				}

				case _: {
					#if !modifaxe_parser_no_error_check
					onError(UnexpectedChar(c));
					#end
				}
			}

			pos++;
		}

		return if(!hasStarted) {
			// empty line; return `null`.
			null;
		} else {
			// end of file, return what's left.
			content.substring(start, end + 1);
		}
	}

	public function nextBool(defaultValue: Bool): Bool {
		final line = nextValueText();
		if(line != null) {
			return line == "true";
		}
		return defaultValue;
	}

	public function nextInt(defaultValue: Int): Int {
		final line = nextValueText();
		if(line != null) {
			return Std.parseInt(line);
		}
		return defaultValue;
	}

	public function nextFloat(defaultValue: Float): Float {
		final line = nextValueText();
		if(line != null) {
			return Std.parseFloat(line);
		}
		return defaultValue;
	}

	public function nextString(defaultValue: String) {
		final line = nextValueText();
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
		onError(ExpectedChar(91));
		#end
		return false;
	}

	/**
		Checks and skips the current identifier.

		If it's a valid identifier, `pos` is set to the end.
		If not, return `false`.
	**/
	inline function expectIdentifier(allowDot: Bool) {
		if(!nextIdentifier(false)) {
			#if !modifaxe_parser_no_error_check
			onError(ExpectedIdentifier);
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
				onError(ExpectedBool);
				#end
			}
		}
	}

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
			onError(ExpectedDigit);
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

	function expectFloat() {
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
			onError(ExpectedDigit);
			#end
		}
		trace(pos);

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

	function expectString() {
		// TODO write string parse
	}
}
