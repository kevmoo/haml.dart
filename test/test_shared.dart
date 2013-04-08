library test.shared;

import 'dart:io';
import 'dart:json' as json;
import 'package:pathos/path.dart' as pathos;

const _jsonTestPath = 'resource/haml-spec/tests.json';

Map<String, Map> getHamlSpecTests() {
  final jsonFile = new File(pathos.normalize(_jsonTestPath));

  return json.parse(jsonFile.readAsStringSync());
}
