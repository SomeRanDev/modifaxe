package modifaxe.runtime;

#if !modifaxe_parser_no_error_check

/**
	The error type for `ModParser`.

	Every type of error can be represented with this enum.
**/
@:using(modifaxe.runtime.ModParserError.ModParserErrorFunctions)
enum ModParserError {
	UnexpectedChar(charCode: Int);

	ExpectedChar(charCode: Int);
	ExpectedIdentifier;
	ExpectedBool;
	ExpectedDigit;

	SectionShouldBeStartOfLine;
	EntryShouldBeStartOfLine;
	UnsupportedEscapeSequence;
}

/**
	Provides functions for `ModParserError`.
**/
class ModParserErrorFunctions {
	/**
		Returns the message the `ModParserError` should print.
	**/
	public static function getMessage(error: ModParserError) {
		return switch(error) {
			case UnexpectedChar(String.fromCharCode(_) => charString): 'Unexpected character $charString';
			case ExpectedChar(String.fromCharCode(_) => charString): 'Expected character $charString';
			case ExpectedIdentifier: 'Expected identifier';
			case ExpectedBool: 'Expected true or false';
			case ExpectedDigit: 'Expected number';
			case SectionShouldBeStartOfLine: 'Section should start at the beginning of the line';
			case EntryShouldBeStartOfLine: 'Entry should start at the beginning of the line';
			case UnsupportedEscapeSequence: 'Unsupported escape sequence';
		}
	}
}

#end
