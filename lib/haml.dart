library haml;

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:bot/bot.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/xml.dart' as xmlp;
import 'package:haml/core.dart';

import 'package:haml/dart_grammar.dart' as dart;
import 'package:haml/html.dart';

part 'src/haml/haml_grammar_parser.dart';

String hamlStringToHtml(String hamlString,
                        { HtmlFormat format: HtmlFormat.HTML5,
  dart.ExpressionEvaluator eval: null}) {
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
    { HtmlFormat format: HtmlFormat.HTML5, dart.ExpressionEvaluator eval: null}) {
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
