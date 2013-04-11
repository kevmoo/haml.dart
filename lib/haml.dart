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
