library test.haml;

import 'package:unittest/unittest.dart';
import 'package:okoboji/core.dart';
import 'package:okoboji/haml.dart';
import '../test_shared.dart';


void main() {

  final jsonValue = getHamlSpecTests();

  jsonValue.forEach((groupName, Map<String, Map> testMap) {
    group(groupName, () {

      testMap.forEach((String testName, Map testData) {
        group(testName, () {

          final data = new _SpecData(testData);

          test('stream', () {
            _testStream(data);
          });

          /*
           * TODO: this is coming back with new hotness soonish
          test('full parser', () {
            _doTest(data);
          });
          */
        });
      });

    });
  });

  final active = ['a simple Haml tag', 'Inline content simple tag',
                  'a tag with colons', 'a tag with underscores',
                  'a tag with PascalCase', 'a tag with camelCase',
                  ' - headers ', 'basic Haml tags and CSS',
                  'whitespace removal', 'whitespace preservation',
                  'tags with nested content', 'tags with inline content',
                  'tags with unusual'];

  filterTests((TestCase tc) {
    return true;
    if(active.any((n) => tc.description.contains(n))) {
      return true;
    }

    print('skipping:\t${tc.description}');

    return false;
  });
}

void _testStream(_SpecData data) {
  print('\nhaml');
  print(data.haml);

  print('\nhtml');
  print(data.html);

  final List<Entry> result = stringToHamlEntry().single(data.haml).toList();

  final List<String> lines = htmlEntryToHtml().map(result).toList();

  final value = lines.join();
  print("**VALUE**");
  print(value);

  expect(value, equals(data.html));

}

/* TODO: this is coming back
void _doTest(_SpecData data) {
  // print(data.haml);
  // print(data.html);
  final parseResult = parse(data.haml, format: data.format);
  expect(parseResult, equals(data.html),
      reason: data.haml);
}
*/

class _SpecData {
  final String haml;
  final String html;
  final HamlFormat format;
  final bool escapeHtml;
  final Map<String, dynamic> locals;

  _SpecData.raw(this.haml, this.html, this.format, this.escapeHtml,
      this.locals) {
    assert(html != null);
    assert(haml != null);
    assert(format != null);
  }

  factory _SpecData(Map<String, dynamic> data) {
    final String haml = data.remove('haml');
    final String html = data.remove('html');

    bool optional = data.remove('optional');
    if(optional == null) {
      optional = false;
    }

    //
    // Config
    //
    Map configMap = data.remove('config');
    configMap = configMap == null ? {} : configMap;

    String format = configMap.remove('format');
    format = format == null ? 'html5' : format;

    final hamlFormat = HamlFormat.parse(format);

    String escapeHtml = configMap.remove('escape_html');
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
    Map locals = data.remove('locals');
    locals = locals == null ? {} : locals;

    return new _SpecData.raw(haml, html, hamlFormat, escapeVal, locals);
  }

}

