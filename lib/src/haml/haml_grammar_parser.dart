part of haml;

class HamlEntityGrammar extends CompositeParser {
  static final _instance = new HamlEntityGrammar._internal();

  static HamlEntityGrammar get instance {
    var val = _instance;
    if(val == null) {
      // silly way to make sure every call throws an exception, even though
      // subsequent calls to the static var will return null after the first
      // call fails
      val = new HamlEntityGrammar._internal();
    }
    return val;
  }

  static Parser get unquotedValue => instance['unquoted-value'];

  HamlEntityGrammar._internal() : super();

  factory HamlEntityGrammar() => instance;

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

  static const String _alwaysEscapePrefix = '&';
  static const String _neverEscapePrefx = '!';

  void initialize() {
    def('start', ref('entity').end());

    def('entity', ref('doctype') | ref('element') | ref('comment') |
        ref('evaluate') | ref('text'));

    def('element', ref('named-element')
        .or(ref('implicit-div-element'))
        .seq(ref('attributes').optional())
        .seq(ref('special-instructions').optional())
        .seq((ref('content') | whitespace()).optional()));

    //
    // Attribute parsing shared
    //

    // TODO: a good start, but probably not right
    def('attribute-name', ref('nameToken'));

    def('quoted-value', ref('single-quoted-value')
        .or(ref('double-quoted-value'))
        .pick(1));

    def('single-quoted-value', char("'")
        .seq(char("'").neg().star().flatten())
        .seq(char("'")));

    def('double-quoted-value', char('"')
        .seq(char('"').neg().star().flatten())
        .seq(char('"')));

    // TODO: should we call this 'expression'?
    def('unquoted-value', dart_grammar.dartIdentifier | dart_grammar.dartNumber);

    def('attributes', ref('html-attributes').or(ref('ruby-attributes')));

    //
    // HTML attributes  ( a = 'b' ...)
    //

    def('html-attributes', char('(')
        .seq(ref('spaces').optional())
        .seq(ref('html-attribute')
            .separatedBy(ref('spaces'), includeSeparators: false, optionalSeparatorAtEnd: true))
        .seq(char(')'))
        .pick(2));

    def('html-attribute', ref('attribute-name')
        .seq(ref('spaces').optional())
        .seq(char('='))
        .seq(ref('spaces').optional())
        .seq(ref('quoted-value').or(ref('unquoted-value')))
        .permute([0, 4])
        );

    //
    // Ruby attributes { :a => 'b', ... }
    //

    def('ruby-attributes', char('{')
        .seq(ref('spaces').optional())
        .seq(ref('ruby-attribute')
            .separatedBy(ref('space-comma-space'), includeSeparators: false))
        .seq(ref('spaces').optional())
        .seq(char('}'))
        .pick(2));

    def('space-comma-space',
        ref('spaces').optional()
        .seq(char(','))
        .seq(ref('spaces').optional()));

    def('ruby-attribute',
        ref('ruby-hash-key')
        .seq(ref('spaces').optional())
        .seq(string('=>'))
        .seq(ref('spaces').optional())
        .seq(ref('quoted-value').or(ref('unquoted-value')))
        .permute([0, 4])
        );

    def('ruby-hash-key', ref('ruby-hash-colon-key').or(ref('ruby-hash-quoted-key')));

    def('ruby-hash-colon-key', char(':').seq(ref('attribute-name')).pick(1));

    def('ruby-hash-quoted-key', ref('quoted-value'));

    //
    // evaluate
    //
    def('evaluate', (char(_neverEscapePrefx) | char(_alwaysEscapePrefix)).optional()
        .seq(char('='))
        .seq(any().plus().flatten().trim())
        .permute([0,2]));

    //
    // comments
    //
    def('comment', ref('silent-comment') | ref('markup-comment'));

    def('markup-comment', ref('markup-comment-one-line'));

    def('markup-comment-one-line',
        char('/')
        .seq(ref('spaces'))
        .seq(any().plus().flatten())
        .pick(2));

    def('silent-comment', string('-#').seq(any().star()).flatten());

    //
    // and other things...
    //

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

  HamlEntityParser() : super._internal();

  @override
  void initialize() {
    super.initialize();

    action('doctype', (value) => new DocTypeEntry(value));

    action('element', (List value) {
      assert(value.length == 4);

      List head = value[0];
      assert(head.length == 2);
      String name = head[0];

      // value is either String or list of String
      Map<String, dynamic> idAndClassValues = head[1];

      final attributesArray = value[1];

      if(attributesArray != null) {
        attributesArray.forEach((List content) {
          assert(content.length == 2);
          String attrName = content[0];

          var attrValue = content[1];

          var existingValue = idAndClassValues[attrName];
          if(existingValue is List) {
            existingValue.add(attrValue);
          } else {
            idAndClassValues[attrName] = attrValue;
          }

        });
      }

      final specialInstructions = value[2];

      bool selfClosing = null;
      if(specialInstructions == '/') {
        selfClosing = true;
      }

      final content = value[3];

      if(content == null || content.trim().isEmpty) {
        return new ElementEntry(name, idAndClassValues, selfClosing: selfClosing);
      } else {
        assert(selfClosing == null);
        return new ElementEntryWithSimpleContent(name, idAndClassValues, content);
      }
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

    action('unquoted-value', (String value) {
      return new InlineExpression(value);
    });

    action('markup-comment-one-line', (String value) {
      return new OneLineMarkupComment(value);
    });

    action('evaluate', (List<String> value) {
      assert(value.length == 2);

      final escapeFlag = value[0];
      bool escapeVal;

      if(escapeFlag == null) {
        escapeVal = null;
      } else if(escapeFlag == _alwaysEscapePrefix) {
        escapeVal = true;
      } else if(escapeFlag == _neverEscapePrefx) {
        escapeVal = false;
      } else {
        throw 'Invalid escape flag "$escapeFlag"';
      }

      final val = value[0];
      assert(val != null);

      throw 'evaluate is not finished...';
    });

    action('silent-comment', (String value) {
      return new SilentComment(value);
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
          final idList = values.putIfAbsent('id', () => new List());
          // for ids, last one wins, so clear it out
          idList.clear();
          idList.add(value);
          break;
        case '.':
          final classList = values.putIfAbsent('class', () => new List());
          classList.add(value);
          break;
        default:
          throw 'provided prefix value "$tag" is not supported';
      }

    });

    return values;
  }
}
