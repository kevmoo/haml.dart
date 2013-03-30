part of haml;

class HamlParser extends HamlGrammar {
  void initialize() {
    super.initialize();

    action('document', (each) => new XmlDocument([each.single]));

    action('element', (each) => new XmlElement(each[1], [], []));

    action('nameToken', (each) => new XmlName(each));

  }

}
