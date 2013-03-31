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
        test(testName, () {
          _doTest(data);
        });
      });

    });
  });

  final active = ['a simple Haml tag', 'Inline content simple tag',
                  'a tag with colons', 'a tag with underscores',
                  'a tag with PascalCase', 'a tag with camelCase'];
  filterTests((TestCase tc) => active.any((n) => tc.description.endsWith(n)));
}

void _doTest(_SpecData data) {
  final parseResult = haml.parse(data.haml);
  expect(parseResult, equals(data.html),
      reason: data.haml);
}

class _SpecData {
  final String haml;
  final String html;
  final String format;
  final bool escapeHtml;
  final Map<String, dynamic> locals;

  _SpecData.raw(this.haml, this.html, this.format, this.escapeHtml,
      this.locals) {
    assert(html != null);
    assert(haml != null);
    assert(['html5','html4','xhtml'].contains(format));
  }

  factory _SpecData(Map<String, dynamic> data) {
    final haml = data.remove('haml');
    final html = data.remove('html');

    var optional = data.remove('optional');
    if(optional == null) {
      optional = false;
    }

    //
    // Config
    //
    var configMap = data.remove('config');
    configMap = configMap == null ? {} : configMap;

    var format = configMap.remove('format');
    format = format == null ? 'html5' : format;

    var escapeHtml = configMap.remove('escape_html');
    escapeHtml = escapeHtml == null ? 'false' : escapeHtml;

    bool escapeVal;
    if(escapeHtml == 'true') {
      escapeVal = true;
    } else if(escapeHtml == 'false') {
      escapeVal = false;
    } else {
      throw 'huh?';
    }

    //
    // Locals
    //
    var locals = data.remove('locals');
    locals = locals == null ? {} : locals;

    return new _SpecData.raw(haml, html, format, escapeVal, locals);
  }

}

