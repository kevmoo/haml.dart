import 'dart:async';
import 'dart:html' as html;

import 'package:js/js.dart' as js;

import 'package:okoboji/core.dart';
import 'package:okoboji/haml.dart';


void main() {
  html.ButtonElement button = html.query('#convert');

  button.onClick.listen(_convertClick);

}

void _convertClick(args) {
  print('click!');

  var sourceVal = _getSourceValue();
  print('value: $sourceVal');

  _setOutputValue('working...\n\n' + sourceVal);

  runAsync(() {
    var parsedOutput = _test(sourceVal);
    _setOutputValue(parsedOutput);

  });



}

String _getSourceValue() {
  return js.context['window']['_sourceCodeMirror']['getValue']();
}

void _setOutputValue(String value) {
  js.context['window']['_outputCodeMirror']['setValue'](value);
}



String _test(String input) {
  final List<Entry> result = stringToHamlEntry().single(input).toList();

  final List<String> lines = htmlEntryToHtml()
      .map(result).toList();

  return lines.join();
}
