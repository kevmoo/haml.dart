part of haml;

class HamlParser extends HamlGrammar {
  void initialize() {
    super.initialize();

    action('document', (each) => new XmlDocument([each.single]));

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

  }

}
