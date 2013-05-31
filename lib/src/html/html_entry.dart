part of html;

abstract class HtmlEntry implements EntryValue {

  void write(HtmlFormat format, EventSink<String> sink, EntryType nextType,
             dart.ExpressionEvaluator eval);

  void close(HtmlFormat format, EventSink<String> sink, EntryType nextType) {
    throw 'not supported';
  }

  static void writeEntry(HtmlFormat format, EventSink<String> sink,
                         Entry current, EntryType nextType,
                         dart.ExpressionEvaluator eval) {
    if(current is HtmlEntry) {
      current.write(format, sink, nextType, eval);
    } else {
      throw 'not sure what to do here...';
    }
  }

  static void closeEntry(HtmlFormat format, EventSink<String> sink,
                         Entry current, EntryType nextType) {
    if(current is HtmlEntry) {
      current.close(format, sink, nextType);
    } else {
      throw 'not supported?';
    }
  }
}

abstract class SoloHtmlEntry extends HtmlEntry {

  @override
  void write(HtmlFormat format, EventSink<String> sink, EntryType nextType,
             dart.ExpressionEvaluator eval) {
    if(nextType == EntryType.INDENT) {
      throw new HtmlError('Child content is not supported');
    }

    writeSolo(format, sink, eval);

    if(nextType != EntryType.EOF) {
      sink.add('\n');
    }
  }

  void writeSolo(HtmlFormat format, EventSink<String> sink,
                 dart.ExpressionEvaluator eval);
}

class SilentComment extends HtmlEntry {
  final String value;

  SilentComment(this.value);

  void write(HtmlFormat format, EventSink<String> sink, EntryType nextType,
             dart.ExpressionEvaluator eval) {
    // noop!
  }
}

class OneLineMarkupComment extends SoloHtmlEntry {
  final String value;

  OneLineMarkupComment(this.value);

  @override
  void writeSolo(HtmlFormat format, EventSink<String> sink,
             dart.ExpressionEvaluator eval) {
    sink.add('<!-- $value -->');
  }
}

/**
 * An [escapeFlag] value of [null] implies the parser setting should be used.
 */
class StringExpressionEntry extends SoloHtmlEntry {
  final dart.InlineExpression expression;
  final bool escapeFlag;

  StringExpressionEntry(this.expression, this.escapeFlag) {
    assert(expression != null);
  }

  @override
  void writeSolo(HtmlFormat format, EventSink<String> sink,
             dart.ExpressionEvaluator eval) {
    var stringValue = eval(expression).toString();

    if(escapeFlag == true) {
      stringValue = _htmlEscape(stringValue);
    }

    sink.add(stringValue);
  }

  @override
  String toString() => expression.toString();
}

class StringElementEntry extends SoloHtmlEntry {
  final String value;

  StringElementEntry(this.value) {
    assert(value != null);
  }

  @override
  void writeSolo(HtmlFormat format, EventSink<String> sink,
             dart.ExpressionEvaluator eval) {
    sink.add(value);
  }

  @override
  String toString() => value;
}

class ElementEntryWithSimpleContent extends ElementEntry {
  final String content;

  ElementEntryWithSimpleContent(String name, Map<String, dynamic> attributes,
                                this.content) : super(name, attributes);

  @override
  void write(HtmlFormat format, EventSink<String> sink, EntryType nextType,
             dart.ExpressionEvaluator eval) {
    if(nextType == EntryType.INDENT) {
      throw new HtmlError('The parent element "$name" already has content.');
    }

    sink.add("<${name}${_getAttributeString(format, eval)}>$content</${name}>");
    if(nextType != EntryType.EOF) {
      sink.add('\n');
    }
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
  void write(HtmlFormat format, EventSink<String> sink, EntryType nextType,
             dart.ExpressionEvaluator eval) {
    sink.add("<${name}${_getAttributeString(format, eval)}");
    if(nextType == EntryType.INDENT) {
      // close out the tag with a newline
      sink.add(">\n");
    } else {
      // close out the tag as a solo tag -- format dependant

      if(!selfClosing) {
        sink.add("></${name}>");
      } else {
        switch(format) {
          case HtmlFormat.HTML5:
            sink.add(">");
            break;
          case HtmlFormat.XHTML:
            sink.add(" />");
            break;
          case HtmlFormat.HTML4:
            sink.add(">");
            break;
          default:
            throw 'have not got around to $format yet';
        }
      }
      if(nextType != EntryType.EOF) {
        sink.add('\n');
      }
    }
  }

  @override
  void close(HtmlFormat format, EventSink<String> sink, EntryType nextType) {
    sink.add("</${value}>");
    if(nextType != EntryType.EOF) {
      sink.add('\n');
    }
  }

  String _getAttributeString(HtmlFormat format, dart.ExpressionEvaluator eval) {
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

        if(format == HtmlFormat.XHTML) {
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

class DocTypeEntry extends HtmlEntry {
  final String label;

  DocTypeEntry([this.label]) {
    assert(label == null || !label.startsWith('!'));
  }

  String formatLabel(HtmlFormat format) {
    if(format == HtmlFormat.XHTML && label == 'XML') {
      return "<?xml version='1.0' encoding='utf-8' ?>";
    }

    final parseVal = getDocType(format, label);

    if(parseVal == null) {
      return '';
    }

    return "<!DOCTYPE$parseVal>";
  }

  @override
  void write(HtmlFormat format, EventSink<String> sink, EntryType nextType,
             dart.ExpressionEvaluator eval) {
    assert(nextType != EntryType.INDENT);
    sink.add(formatLabel(format));

    // TODO: if next != null, write newline?
  }

  @override
  String get value => label == null ? '!!!' : '!!! $label';

  @override
  String toString() => value;

  static String getDocType(HtmlFormat format, String label) {
    switch(format) {
      case HtmlFormat.HTML4:
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
      case HtmlFormat.XHTML:
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
 * DARTBUG: https://code.google.com/p/dart/issues/detail?id=1657
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

