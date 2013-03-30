library test.haml;

import 'dart:io';
import 'dart:json' as json;

import 'package:unittest/unittest.dart';
import 'package:pathos/path.dart' as pathos;

import 'package:okoboji/haml.dart' as haml;

const _jsonTestPath = 'test/haml-spec/tests.json';

const _tempJsonContent = '''
{
  "basic Haml tags and CSS": {

    "a simple Haml tag" : {
      "haml" : "%p",
      "html" : "<p></p>"
    }
  }
}
''';

void main() {

  //final jsonFile = new File(pathos.normalize(_jsonTestPath));

  //final Map<String, Map> jsonValue = json.parse(jsonFile.readAsStringSync());

  final Map<String, Map> jsonValue = json.parse(_tempJsonContent);




  test('haml-spec', () {

    jsonValue.forEach((groupName, Map<String, Map> testMap) {

        testMap.forEach((String testName, Map testData) {
          final data = new _SpecData(testData);
          print('$groupName - $testName');
          if(data.skip) {
            print('skip');
          } else {
            print('test');
            _doTest(data);
          }
        });

      });
    });
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

