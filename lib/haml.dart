library haml;

import 'package:petitparser/petitparser.dart';
import 'package:petitparser/xml.dart' as xmlp;

part 'src/haml/grammar.dart';
part 'src/haml/parser.dart';
part 'src/haml/nodes.dart';

String parse(String sourceHaml, {HamlFormat format: HamlFormat.HTML5}) {
  final parser = new HamlParser(format: format);
  var result = parser.parse(sourceHaml).result;
  print(result);
  return result.doFormat();
}
