part of haml;

/*
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

      //print(nodes.map((n) => Error.safeToString(n)).join(', '));
      return new XmlDocument(nodes);
    });

    action('element', (each) {
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
      if(format == HamlFormat.XHTML && label == 'XML') {
        return new XmlProcessing('xml', r''' version='1.0' encoding='utf-8' ''');
      }

      final data = DocTypeEntry.getDocType(format, label);

      if(data != null) {
        return new XmlDoctype(data);
      }

    });

  }
}
*/
