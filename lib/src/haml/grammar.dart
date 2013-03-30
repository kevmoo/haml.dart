part of haml;

class HamlGrammar extends CompositeParser {

  static final _newLine = Token.newlineParser();


  void initialize() {
    def('start', ref('document').end());

    def('document', ref('element').separatedBy(_newLine,
        optionalSeparatorAtEnd: true));

    def('element', char('%')
        .seq(ref('nameToken'))
        .pick(1)
        .seq(ref('spaces').seq(ref('content')).pick(1).optional()));

    def('nameToken', ref('nameStartChar')
      .seq(ref('nameStartChar').star())
      .flatten());
    def('nameStartChar', pattern(xmlp.XmlGrammar.NAME_START_CHARS));
    def('nameChar', pattern(xmlp.XmlGrammar.NAME_CHARS));

    def('spaces', char(' ').plus());

    def('content', ref('inline'));

    def('inline', _newLine.neg().star().flatten());

  }

}
