part of html;

abstract class HtmlEntry implements EntryValue {

  void write(HamlFormat format, EventSink<String> sink, Entry next,
             dart.ExpressionEvaluator eval);

  void close(HamlFormat format, EventSink<String> sink, Entry next) {
    throw 'not supported';
  }

  static void writeEntry(HamlFormat format, EventSink<String> sink,
                         Entry current, Entry next,
                         dart.ExpressionEvaluator eval) {
    if(current is HtmlEntry) {
      // NOTE: this should be fine. Editor type analysis fail
      current.write(format, sink, next, eval);
    } else {
      throw 'not sure what to do here...';
    }
  }

  static void closeEntry(HamlFormat format, EventSink<String> sink,
                         Entry current, Entry next) {
    if(current is HtmlEntry) {
      // NOTE: this should be fine. Editor type analysis fail
      current.close(format, sink, next);
    } else {
      throw 'not supported?';
    }
  }
}

class SilentComment implements HtmlEntry {
  final String value;

  SilentComment(this.value);

  void write(HamlFormat format, EventSink<String> sink, Entry next,
             dart.ExpressionEvaluator eval) {
    // noop!
  }

  void close(HamlFormat format, EventSink<String> sink, Entry next) {
    // noop!
  }
}

class OneLineMarkupComment implements HtmlEntry {
  final String value;

  OneLineMarkupComment(this.value);

  @override
  void write(HamlFormat format, EventSink<String> sink, Entry next,
             dart.ExpressionEvaluator eval) {
    if(next is EntryIndent) {
      throw 'not supported';
    }

    sink.add('<!-- $value -->');
    if(next != null) {
      sink.add('\n');
    }
  }
}

/**
 * An [escapeFlag] value of [null] implies the parser setting should be used.
 */
class StringExpressionEntry implements HtmlEntry {
  final dart.InlineExpression expression;
  final bool escapeFlag;

  StringExpressionEntry(this.expression, this.escapeFlag) {
    assert(expression != null);
  }

  @override
  void write(HamlFormat format, EventSink<String> sink, Entry next,
             dart.ExpressionEvaluator eval) {
    if(next is EntryIndent) {
      throw new HamlError('Cannot add nested content under a '
          ' StringExpressionEntry');
    }

    var stringValue = eval(expression).toString();

    if(escapeFlag == true) {
      stringValue = _htmlEscape(stringValue);
    }

    sink.add(stringValue);
    if(next != null) {
      sink.add('\n');
    }
  }

  @override
  String toString() => expression.toString();
}

class StringElementEntry implements HtmlEntry {
  final String value;

  StringElementEntry(this.value) {
    assert(value != null);
  }

  @override
  void write(HamlFormat format, EventSink<String> sink, Entry next,
             dart.ExpressionEvaluator eval) {
    if(next is EntryIndent) {
      throw new HamlError('Cannot add nested content under a StringEntry: '
          '"$value"');
    }

    sink.add(value);
    if(next != null) {
      sink.add('\n');
    }
  }

  @override
  String toString() => value;
}

class ElementEntryWithSimpleContent extends ElementEntry {
  final String content;

  ElementEntryWithSimpleContent(String name, Map<String, dynamic> attributes,
                                this.content) : super(name, attributes);

  @override
  void write(HamlFormat format, EventSink<String> sink, Entry next,
             dart.ExpressionEvaluator eval) {
    if(next is EntryIndent) {
      throw new HamlError('The parent element "$name" already has content.');
    }

    sink.add("<${name}${_getAttributeString(format, eval)}>$content</${name}>");
    if(next != null) {
      sink.add('\n');
    }
  }

  @override
  void close(HamlFormat format, EventSink<String> sink, Entry next) {
    throw 'not supported';
  }
}

class ElementEntry implements HtmlEntry {
  final String name;
  final bool selfClosing;
  final Map<String, dynamic> _attributes;

  String get value => name;

  ElementEntry(String name, Map<String, dynamic> attributes,
      {bool selfClosing}) :
    this.name = name,
    this._attributes = attributes,
    this.selfClosing = (selfClosing == null) ?
        _isSelfClosingTag(name) : selfClosing {
    assert(elementNameParser.accept(name));
  }

  @override
  String toString() => '<$name>';

  @override
  void write(HamlFormat format, EventSink<String> sink, Entry next,
             dart.ExpressionEvaluator eval) {
    sink.add("<${name}${_getAttributeString(format, eval)}");
    if(next is EntryIndent) {
      // close out the tag with a newline
      sink.add(">\n");
    } else {
      // close out the tag as a solo tag -- format dependant

      if(!selfClosing) {
        sink.add("></${name}>");
      } else {
        switch(format) {
          case HamlFormat.HTML5:
            sink.add(">");
            break;
          case HamlFormat.XHTML:
            sink.add(" />");
            break;
          case HamlFormat.HTML4:
            sink.add(">");
            break;
          default:
            throw 'have not got around to $format yet';
        }
      }
      if(next != null) {
        sink.add('\n');
      }
    }
  }

  @override
  void close(HamlFormat format, EventSink<String> sink, Entry next) {
    sink.add("</${value}>");
    if(next != null) {
      sink.add('\n');
    }
  }

  String _getAttributeString(HamlFormat format, dart.ExpressionEvaluator eval) {
    final buffer = new StringBuffer();
    // first, must be ordered
    final sortedKeys = _attributes.keys
        .toList()..sort();

    sortedKeys.forEach((String key) {
      var value = _attributes[key];
      if(value is List) {
        assert(!value.isEmpty);

        final List<String> vals = value.map((v) => _getValue(eval, v))
            .toList();

        // special case for ID
        // ids get joined via '_', not space
        // ids are also NOT sorted.
        if(key == 'id') {
          value = vals.join('_');
        } else {
          vals.sort();
          value = vals.join(' ');
        }
      }

      value = _getValue(eval, value);

      if(value is bool) {
        if(value == false) {
          // noop. No attribute should be written
          return;
        }

        if(format == HamlFormat.XHTML) {
          // just print out the key as the value
          value = key;
        } else {
          // else, just write the attribute name alone and call it good
          buffer.write(" $key");
          return;
        }
      }

      assert(value is String);

      buffer.write(" $key='$value'");
    });

    return buffer.toString();
  }

  static dynamic _getValue(dart.ExpressionEvaluator eval, dynamic input) {
    if(input is dart.InlineExpression) {
      input = eval(input);
      assert(input is! dart.InlineExpression);
    }

    if(input is num) {
      return input.toString();
    } else if(input is String) {
      return input;
    } else if(input is bool) {
      // just let it pass through
      return input;
    } else {
      throw 'Value not supported: $input';
    }
  }

  static bool _isSelfClosingTag(String tag) {
    const _selfClosing = const ['meta', 'input', 'img'];
    return _selfClosing.contains(tag);
  }

  static final Parser elementNameParser =
      pattern(xmlp.XmlGrammar.NAME_START_CHARS)
      .seq(pattern(xmlp.XmlGrammar.NAME_CHARS).star())
      .flatten();
}

class DocTypeEntry implements HtmlEntry {
  final String label;

  DocTypeEntry([this.label]) {
    assert(label == null || !label.startsWith('!'));
  }

  String formatLabel(HamlFormat format) {
    if(format == HamlFormat.XHTML && label == 'XML') {
      return "<?xml version='1.0' encoding='utf-8' ?>";
    }

    final parseVal = getDocType(format, label);

    if(parseVal == null) {
      return '';
    }

    return "<!DOCTYPE$parseVal>";
  }

  @override
  void write(HamlFormat format, EventSink<String> sink, Entry next,
             dart.ExpressionEvaluator eval) {
    assert(next is! EntryIndent);
    sink.add(formatLabel(format));

    // TODO: if next != null, write newline?
  }

  @override
  String get value => label == null ? '!!!' : '!!! $label';

  @override
  String toString() => value;

  static String getDocType(HamlFormat format, String label) {
    switch(format) {
      case HamlFormat.HTML4:
        if(label == null)
          return r''' html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"''';

        switch(label) {
          case 'strict':
            return r''' html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd"''';
          case 'frameset':
            return r''' html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd"''';
          default:
            return null;
        }
        break;
      case HamlFormat.XHTML:
        switch(label) {
          case 'frameset':
            return r''' html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd"''';
          case '5':
            return ' html';
          case 'mobile':
            return r''' html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd"''';
          case 'basic':
            return r''' html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd"''';
          case '1.1':
            return r''' html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"''';
          case 'XML':
            throw 'should never get here...';
          default:
            return r''' html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"''';
        }
        break;
      default:
        switch(label) {
          case 'XML':
            return null;
          default:
            return ' html';
        }
     }
  }
}

/*
 * Copied from pub 'intl' package. Can't wait for this to get standardized
 * ...somewhere
 */
String _htmlEscape(String text) {
 // TODO(alanknight): This is copied into here directly to avoid having a
 // dependency on the htmlescape library, which is difficult to do in a way
 // that's compatible with both package: links and direct links in the SDK.
 // Once pub is used in test.dart (Issue #4968) this should be removed.
 // TODO(efortuna): A more efficient implementation.
 return text.replaceAll("&", "&amp;")
     .replaceAll("<", "&lt;")
     .replaceAll(">", "&gt;")
     .replaceAll('"', "&quot;")
     .replaceAll("'", "&apos;");
}

