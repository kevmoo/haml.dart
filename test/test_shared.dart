library test.shared;

import 'dart:io';
import 'dart:json' as json;
import 'package:pathos/path.dart' as pathos;

const _jsonTestPath = 'resource/haml-spec/tests.json';

Map<String, Map> getHamlSpecTests() {
  final jsonFile = new File(pathos.normalize(_jsonTestPath));

  return json.parse(jsonFile.readAsStringSync());
}

const EXPRESSIONS = const {
  '1' : 1,
  '10': 10,
  '1.1': 1.1,
  '12.2': 12.2,
  '1.42e5': 1.42e5,
  'true': true,
  'false': false,
  'null': null,
  '"string"': 'string',
  "'string'": 'string'
};
