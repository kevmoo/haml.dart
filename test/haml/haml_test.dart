library test.haml;

import 'dart:io';
import 'dart:json' as json;

import 'package:unittest/unittest.dart';
import 'package:pathos/path.dart' as pathos;

import 'package:okoboji/haml.dart' as haml;

const _jsonTestPath = 'test/haml-spec/tests.json';

void main() {

  final jsonFile = new File(pathos.normalize(_jsonTestPath));

  final Map<String, Map> jsonValue = json.parse(jsonFile.readAsStringSync());

  final skips = [];

  jsonValue.forEach((groupName, Map<String, Map> testMap) {
    group(groupName, () {

      testMap.forEach((String testName, Map testData) {
        final data = new _SpecData(testData);
        if(data.skip) {
          skips.add('$groupName - $testName');
        } else {
          test(testName, () {
            _doTest(data);
          });
        }
      });

    });
  });

  final active = ['a simple Haml tag',
                  'Inline content simple tag', 'a tag with colons',
                  'a tag with underscores', 'a tag with PascalCase', 'a tag with camelCase'];
  filterTests((TestCase tc) => active.any((n) => tc.description.endsWith(n)));

  print("Skips: ${skips.length}");
}

void _doTest(_SpecData data) {
  final parseResult = haml.parse(data.haml);
  expect(parseResult, equals(data.html),
      reason: data.haml);
}

class _SpecData {
  final String haml;
  final String html;
  final bool skip;

  _SpecData.raw(this.haml, this.html, this.skip) {
    assert(html != null);
    assert(haml != null);
  }

  factory _SpecData(Map<String, dynamic> data) {
    final haml = data.remove('haml');
    final html = data.remove('html');

    var optional = data.remove('optional');
    if(optional == null) {
      optional = false;
    }

    final configMap = data.remove('config');
    final localsMap = data.remove('locals');

    final instance = new _SpecData.raw(haml, html, configMap != null || localsMap != null);

    if(!data.isEmpty) {
      print(data);
      throw 'missed something!';
    }

    return instance;
  }

}

