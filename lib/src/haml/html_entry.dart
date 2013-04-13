part of haml;


abstract class HtmlEntry implements EntryValue {

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

  String get value => name;

  ElementEntry(this.name) {
    assert(elementNameParser.accept(name));
  }

  @override
  String toString() => '<$name>';

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
