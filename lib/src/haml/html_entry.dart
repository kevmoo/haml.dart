part of haml;


abstract class HtmlEntry implements EntryValue {

  void write(HamlFormat format, EventSink<String> sink, Entry next);

  void close(HamlFormat format, EventSink<String> sink) {
    throw 'not supported';
  }

  static void writeEntry(HamlFormat format, EventSink<String> sink,
                         Entry current, Entry next) {
    if(current is HtmlEntry) {
      // NOTE: this should be fine. Editor type analysis fail
      current.write(format, sink, next);
    } else {
      throw 'not sure what to do here...';
    }
  }

  static void closeEntry(HamlFormat format, EventSink<String> sink,
                         Entry current) {
    if(current is HtmlEntry) {
      current.close(format, sink);
    } else {
      throw 'not supported?';
    }
  }
}

class StringEntry implements HtmlEntry {
  final String value;

  StringEntry(this.value) {
    assert(value != null);
  }

  @override
  String toString() => value;
}

class ElementEntry implements HtmlEntry {
  final String name;
  final bool selfClosing;

  String get value => name;

  ElementEntry(String name, {bool selfClosing}) :
    this.name = name,
    this.selfClosing = (selfClosing == null) ?
        _isSelfClosingTag(name) : selfClosing {
    assert(elementNameParser.accept(name));
  }

  @override
  String toString() => '<$name>';

  @override
  void write(HamlFormat format, EventSink<String> sink, Entry next) {
    sink.add("<${name}");
    if(next is EntryIndent) {
      // close out the tag with a newline
      sink.add(">\n");
    } else if(next == null || next is EntryUndent) {
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

      //sink.add("<${value}></${value}>");
    } else {
      throw 'dude...uh..next... $next';
    }
  }

  @override
  void close(HamlFormat format, EventSink<String> sink) {
    sink.add("</${value}>");
  }

  static bool _isSelfClosingTag(String tag) {
    const _selfClosing = const ['meta'];
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
  void write(HamlFormat format, EventSink<String> sink, Entry next) {
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
