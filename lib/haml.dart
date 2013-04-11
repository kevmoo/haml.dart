library haml;

import 'package:meta/meta.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/xml.dart' as xmlp;
import 'package:okoboji/core.dart';

part 'src/haml/grammar.dart';
part 'src/haml/parser.dart';
part 'src/haml/nodes.dart';
part 'src/haml/haml_entity_parser_grammar.dart';

String parse(String sourceHaml, {HamlFormat format: HamlFormat.HTML5}) {
  final parser = new HamlParser(format: format);
  var result = parser.parse(sourceHaml).result;
  // print(result);
  return result.doFormat();
}

Walker<String, Entry> stringToHamlEntry() {
  return stringToLines()
      .chain(linesToIndents())
      .chain(indentsToTokens())
      .chain(tokensToEntries(_getHamlEntry));
}

HamlEntry _getHamlEntry(String value) {
  var result = _entryParser.parse(value);

  if(!result.isSuccess) {
    print(result);
    print(result.message);
    throw 'boo!';
  }

  return result.result;
}

final _entryParser = new HamlEntityParser();
