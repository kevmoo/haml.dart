part of haml;

class HamlFormat {
  static const HamlFormat HTML5 = const HamlFormat._internal('html5');
  static const HamlFormat HTML4 = const HamlFormat._internal('html4');
  static const HamlFormat XHTML = const HamlFormat._internal('xhtml');

  final String name;

  String toString() => 'HamlFormat $name';

  const HamlFormat._internal(this.name);

  static HamlFormat parse(String input) {
    switch(input) {
      case HTML5.name:
        return HTML5;
      case XHTML.name:
        return XHTML;
      case HTML4.name:
        return HTML4;
      default:
        throw 'not impld for $input';
    }
  }
}

class HamlParser extends HamlGrammar {
  final HamlFormat format;

  HamlParser({this.format: HamlFormat.HTML5}) {
    assert(this.format != null);
  }

  void initialize() {
    super.initialize();

    action('document', (each) {
      final List<XmlNode> nodes = new List<XmlNode>();
      if(each[0] != null) {
        nodes.add(each[0]);
      }
      nodes.addAll(each[1]);

      print(nodes.map((n) => Error.safeToString(n)).join(', '));
      return new XmlDocument(nodes);
    });

    action('element', (each) {
      print(each);
      final XmlName name = each[0];

      Iterable<XmlNode> childNodes;
      if(each[1] is String) {
        childNodes = [new XmlText(each[1])];
      } else {
        childNodes = [];
      }
      return new XmlElement(name, [], childNodes);
    });

    action('nameToken', (each) => new XmlName(each));

    action('doctype', (label) {
      print('found label: $label');
      print(format);

      if(format == HamlFormat.XHTML && label == 'XML') {
        return new XmlProcessing('xml', r''' version='1.0' encoding='utf-8' ''');
      }

      final data = _getDocType(label);

      if(data != null) {
        return new XmlDoctype(data);
      }

    });

  }

  String _getDocType(String label) {
    switch(format) {
      case HamlFormat.HTML4:
        switch(label) {
          case 'strict':
            return r''' html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd"''';
          case 'frameset':
            return r''' html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd"''';
          case null:
            return r''' html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"''';
          default:
            return null;
        }
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
