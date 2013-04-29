library haml;

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:logging/logging.dart' as logging;
import 'package:bot/bot.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/xml.dart' as xmlp;
import 'package:haml/core.dart';

import 'package:haml/dart_grammar.dart' as dart_grammar;

part 'src/haml/haml_format.dart';
part 'src/haml/haml_grammar_parser.dart';
part 'src/haml/html_entry.dart';
part 'src/haml/html_writer.dart';
part 'src/haml/inline_expression.dart';

/*
 * TODO: this is coming back...with new hotness
String parse(String sourceHaml, {HamlFormat format: HamlFormat.HTML5}) {
  final parser = new HamlParser(format: format);
  var result = parser.parse(sourceHaml).result;
  // print(result);
  return result.doFormat();
}
*/

// TODO: rename this to stringToHtmlEntry, right?
Walker<String, Entry> stringToHamlEntry() {
  return stringToLines()
      .chain(linesToIndents())
      .chain(indentsToTokens())
      .chain(tokensToEntries(_getHamlEntry));
}

HtmlEntry _getHamlEntry(String value) {
  var result = _entryParser.parse(value);

  if(!result.isSuccess) {
    print(result);
    print(result.message);
    throw 'boo!';
  }

  return result.result;
}

final _entryParser = new HamlEntityParser();

logging.Logger _getLogger(String name) {
  return new logging.Logger(name);
}

class HamlError implements Error {
  final String message;

  HamlError(this.message) {
    requireArgumentNotNullOrEmpty(message, 'message');
  }

  @override
  String toString() => 'HamlError: $message';
}
