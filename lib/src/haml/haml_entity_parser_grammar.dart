part of haml;

class _HamlEnum {
  final String value;
  const _HamlEnum(this.value);
  String toString() => '* $value *';
}

class _SpecialInstruction extends _HamlEnum {
  static const _SpecialInstruction SELF_CLOSING =
      const _SpecialInstruction('self-closing');

  static const _SpecialInstruction REMOVE_WHITESPACE_SURROUNDING =
      const _SpecialInstruction('remove-whitespace-surrounding');

  static const _SpecialInstruction REMOVE_WHITESPACE_WITHIN =
      const _SpecialInstruction('remove-whitespace-within');

  const _SpecialInstruction(String value) : super(value);
}

class HamlEntityGrammar extends CompositeParser {

  static final Parser hamlElementNameParser =
      pattern(xmlp.XmlGrammar.NAME_START_CHARS)
      .seq(pattern(NAME_CHARS_SANS_PERIOD).star())
      .flatten();

  // TODO: this is likely wrong for css names. Need to investigate.
  static final Parser hamlClassNameParser =
      pattern(NAME_CHARS_SANS_PERIOD).plus().flatten();

  // HAML names are valid XML names, EXCEPT period (.) has special meaning
  // as a definer of classes
  static final String NAME_CHARS_SANS_PERIOD =
      '-0-9\u00B7\u0300-\u036F\u203F-\u2040'
      '${xmlp.XmlGrammar.NAME_START_CHARS}';

  void initialize() {
    def('start', ref('entity').end());

    def('entity', ref('doctype').or(ref('element')).or(ref('text')));

    def('element', ref('named-element').or(ref('implicit-div-element'))
        .seq(ref('attributes').optional())
        .seq(ref('special-instructions').optional())
        .seq(ref('content').optional()));

    def('attributes', ref('html-attributes').or(ref('ruby-attributes')));

    def('html-attributes', char('(')
        .seq(char(')').neg().star())
        .seq(char(')'))
        .flatten());

    def('ruby-attributes', char('{')
        .seq(char('}').neg().star())
        .seq(char('}'))
        .flatten());

    def('text', any().star().flatten());

    def('special-instructions', char('/').or(char('>')).or(char('<')));

    def('implicit-div-element', ref('id-def').or(ref('class-def')).plus());

    def('named-element', ref('element-name')
        .seq(ref('id-def').or(ref('class-def')).star()));

    def('id-def', char('#').seq(ref('css-name')));

    def('class-def', char('.').seq(ref('css-name')));

    def('element-name', char('%').seq(ref('nameToken')));

    def('css-name', hamlClassNameParser);

    def('content', ref('spaces').seq(any().star().flatten()).pick(1));

    def('nameToken', hamlElementNameParser);

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
      assert(value.length == 4);

      List head = value[0];
      assert(head.length == 2);
      String name = head[0];

      // TODO: actually support content
      Map<String, List<String>> idAndClassValues = head[1];

      final String attributes = value[1];
      // TODO: at some point need to merge classes and ids here, but for now...

      final specialInstructions = value[2];

      bool selfClosing = null;
      if(specialInstructions == '/') {
        selfClosing = true;
      }

      final content = value[3];

      return new ElementEntry(name, idAndClassValues, selfClosing: selfClosing);
    });

    action('implicit-div-element', (List value) {
      assert(!value.isEmpty);

      var values = _parseClassesAndIds(value);

      return ['div', values];
    });

    action('named-element', (List value) {
      assert(value.length == 2);
      List namedList = value[0];
      assert(namedList.length == 2);
      assert(namedList[0] == '%');

      String name = namedList[1];
      assert(name != null && !name.isEmpty);

      var values = _parseClassesAndIds(value[1]);

      return [name, values];
    });

    action('text', (String value) {
      return new StringEntry(value);
    });
  }

  static Map<String, dynamic> _parseClassesAndIds(List<String> source) {
    Map<String, dynamic> values = { };

    source.forEach((List<String> content) {
      assert(content.length == 2);
      final String tag = content[0];

      // TODO: assert valid namey thing?
      final String value = content[1];
      switch(tag) {
        case '#':
          values['id'] = value;
          break;
        case '.':
          final classArray = values.putIfAbsent('class', () => []);
          classArray.add(value);
          break;
        default:
          throw 'provided prefix value "$tag" is not supported';
      }

    });

    return values;
  }
}
