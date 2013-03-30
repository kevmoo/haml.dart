part of haml;

class HamlGrammar extends CompositeParser {

  static final _newLine = Token.newlineParser();


  void initialize() {
    def('start', ref('document').end());

    def('document', ref('element').separatedBy(_newLine));

    def('element', char('%')
        .seq(ref('nameToken')));

    def('nameToken', ref('nameStartChar')
      .seq(ref('nameStartChar').star())
      .flatten());
    def('nameStartChar', pattern(xmlp.XmlGrammar.NAME_START_CHARS));
    def('nameChar', pattern(xmlp.XmlGrammar.NAME_CHARS));
  }

}
