import 'dart:async';
import 'dart:html' as html;

import 'package:js/js.dart' as js;

import 'package:okoboji/core.dart';
import 'package:okoboji/haml.dart';

html.DivElement _cmOutput;

void main() {
  html.ButtonElement button = html.query('#convert');

  button.onClick.listen(_convertClick);

  _cmOutput = html.query('.CodeMirror.outputCM');
}

void _convertClick(args) {

  var sourceVal = _getSourceValue();

  _setOutputValue('working...\n\n' + sourceVal, {'mode': 'text'});

  runAsync(() {
    String content = '';
    String mode = 'htmlmixed';
    bool lineNumbers = true;
    try {
      content = _test(sourceVal);
      _cmOutput.classes.remove('error');
    } catch (e, stack) {
      _cmOutput.classes.add('error');
      mode = 'text';
      lineNumbers = false;

      content = e.toString() + '\n' + stack.toString();
    }

    _setOutputValue(content, {'lineNumbers': lineNumbers, 'mode': mode});
  });
}

String _getSourceValue() {
  return js.context['window']['_sourceCodeMirror']['getValue']();
}

void _setOutputValue(String value, Map options) {
  js.context['window']['_outputCodeMirror']['setValue'](value);

  options.forEach((k, v) {
    js.context['window']['_outputCodeMirror']['setOption'](k, v);
  });
}

String _test(String input) {
  final List<Entry> result = stringToHamlEntry().single(input).toList();

  final List<String> lines = htmlEntryToHtml()
      .map(result).toList();

  return lines.join();
}
