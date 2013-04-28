library dart_grammar;

import 'package:petitparser/petitparser.dart';

final _grammarInstance = new DartGrammar();

final Parser dartIdentifier = _grammarInstance['IDENTIFIER'].flatten();
final Parser dartNumber = _grammarInstance['NUMBER'].flatten();

/**
 * Only a partial grammar...just for the bits needed by HAML at the moment
 */
class DartGrammar extends CompositeParser {
  void initialize() {
    def('start', ref('IDENTIFIER').end());

    def('DIGIT' , range('0', '9'));
    def('LETTER', letter());
    def('dot', char('.'));
    def('minus', char('-'));
    def('pluz', char('+'));

    def('IDENTIFIER_START_NO_DOLLAR', ref('LETTER') | char('_'));

    def('IDENTIFIER_START', ref('IDENTIFIER_START_NO_DOLLAR') | char('\$'));

    def('IDENTIFIER_PART_NO_DOLLAR', ref('IDENTIFIER_START_NO_DOLLAR') |
        ref('DIGIT'));

    def('IDENTIFIER_PART', ref('IDENTIFIER_START') | ref('DIGIT'));

    def('IDENTIFIER_NO_DOLLAR', ref('IDENTIFIER_START_NO_DOLLAR') &
        ref('IDENTIFIER_PART_NO_DOLLAR').star());

    def('IDENTIFIER', ref('IDENTIFIER_START') & ref('IDENTIFIER_PART').star());

    def('EXPONENT', (char('e') | char('E')) &
        (ref('pluz') | ref('minus')).optional() &
        ref('DIGIT').plus());

    def('NUMBER', ref('DIGIT').plus() & (ref('dot') &
        ref('DIGIT').plus()).optional() & ref('EXPONENT').optional() |
        ref('dot') & ref('DIGIT').plus() & ref('EXPONENT').optional());

  }
}
