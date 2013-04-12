part of haml;

class HamlEntityGrammar extends CompositeParser {

  void initialize() {
    def('start', ref('entity').end());

    def('entity', ref('doctype').or(ref('element')));

    def('element', ref('named-element').or(ref('implicit-div-element'))
        .seq(ref('self-closing'))
        .seq(ref('content').optional()));

    def('self-closing', char('/').optional()
        .map((String char) {
          if(char == null) {
            return false;
          } else if (char == '/') {
            return true;
          } else {
            throw 'not a valid value';
          }
        }));

    def('implicit-div-element', ref('id-def').or(ref('class-def')).plus());

    def('named-element', ref('element-name')
        .seq(ref('id-def').or(ref('class-def')).star()));

    def('id-def', char('#').seq(ref('css-name')));

    def('class-def', char('.').seq(ref('css-name')));

    def('element-name', char('%').seq(ref('nameToken')));

    // TODO: this is likely wrong for css names. Need to investigate.
    def('css-name', ref('nameToken'));

    def('content', ref('spaces').seq(any().star().flatten()).pick(1));

    def('nameToken', ref('nameStartChar')
      .seq(ref('nameChar').star())
      .flatten());
    def('nameStartChar', pattern(xmlp.XmlGrammar.NAME_START_CHARS));
    def('nameChar', pattern(xmlp.XmlGrammar.NAME_CHARS));

    def('doctype', string('!!!')
        .seq(ref('spaces')
            .seq(word().or(char('.')).plus().flatten())
            .pick(1).optional())
         .pick(-1));

    def('spaces', char(' ').plus());

  }
}

class HamlEntityParser extends HamlEntityGrammar {

  @override
  void initialize() {
    super.initialize();

    action('doctype', (value) => new DocTypeEntry(value));
    action('element', (List value) {
      assert(value.length == 3);

      List head = value[0];
      assert(head.length == 2);
      String name = head[0];

      // TODO: actually support content
      Map<String, List<String>> idAndClassValues = head[1];


      final isSelfClosing = value[1];

      final content = value[2];

      return new ElementEntry(name);
    });

    action('implicit-div-element', (List value) {
      assert(!value.isEmpty);
      Map<String, dynamic> values = { 'ids': [], 'classes': [] };

      // TODO: actually populate the ids and classes
      // TODO: share code w/ named-element when we get there

      return ['div', values];
    });

    action('named-element', (List value) {
      assert(value.length == 2);
      List namedList = value[0];
      assert(namedList.length == 2);
      assert(namedList[0] == '%');

      String name = namedList[1];
      assert(name != null && !name.isEmpty);

      var values = { };

      // TODO: actually populate the ids and classes
      // TODO: share code w/ implicit-div-element when we get there

      return [name, values];
    });
  }
}

abstract class HamlEntry implements EntryValue {

}

class ElementEntry implements HamlEntry {
  final String value;

  ElementEntry(this.value) {
    assert(!value.startsWith('%'));
  }


  @override
  String toString() => '<$value>';
}

class DocTypeEntry implements HamlEntry {
  final String value;

  DocTypeEntry([this.value]) {
    assert(value == null || !value.startsWith('!'));
  }

  @override
  String toString() => value == null ? '!!!' : '!!! $value';

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
