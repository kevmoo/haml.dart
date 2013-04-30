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

String hamlStringToHtml(String hamlString,
                        { HamlFormat format: HamlFormat.HTML5,
                          ExpressionEvaluator eval: null}) {
  return _hamlStringToHtmlLines(format: format, eval: eval)
      .single(hamlString)
      .join();
}


Walker<String, Entry> hamlStringToHtmlEntry() {
  return stringToLines()
      .chain(linesToIndents())
      .chain(indentsToTokens())
      .chain(tokensToEntries(_getHamlEntry));
}

Walker<String, String> _hamlStringToHtmlLines(
    { HamlFormat format: HamlFormat.HTML5, ExpressionEvaluator eval: null}) {
  return hamlStringToHtmlEntry()
      .chain(htmlEntryToHtml(format: format, eval: eval));
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
