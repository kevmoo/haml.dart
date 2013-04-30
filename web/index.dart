import 'dart:async';
import 'dart:html' as html;

import 'package:js/js.dart' as js;

import 'package:haml/core.dart';
import 'package:haml/haml.dart';

html.DivElement _cmOutput;

void main() {
  html.ButtonElement button = html.query('#convert');

  button.onClick.listen(_convertClick);

  _cmOutput = html.query('.CodeMirror.outputCM');

  _setOutputValue('loaded', { 'mode': 'text', 'lineNumbers': false });
}

void _convertClick(args) {

  var sourceVal = _getSourceValue();

  var options = {
                 'lineNumbers': false,
                 'mode': 'text'
  };

  _setOutputValue('working...', options);

  runAsync(() {
    String content = '';

    try {
      content = hamlStringToHtml(sourceVal);
      _cmOutput.classes.remove('error');

      options = { 'mode': 'htmlmixed',
                  'lineNumbers': true
                  };

    } catch (e, stack) {
      _cmOutput.classes.add('error');

      options = { 'mode': 'text',
                  'lineNumbers': false};

      content = e.toString() + '\n' + stack.toString();
    }

    _setOutputValue(content, options);
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
