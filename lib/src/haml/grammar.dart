part of haml;

class HamlGrammar extends CompositeParser {

  static final _newLine = Token.newlineParser();


  void initialize() {
    def('start', ref('document').end());

    def('document',
        ref('doctype').optional()
        .seq(ref('element').star()));

    def('doctype', string('!!!')
        .seq(ref('spaces')
            .seq(word().or(char('.')).plus().flatten())
            .pick(1).optional())
         .pick(-1));

    def('element', char('%')
        .seq(ref('nameToken'))
        .seq(ref('content').optional())
        .permute([1,2]));

    def('nameToken', ref('nameStartChar')
      .seq(ref('nameChar').star())
      .flatten());
    def('nameStartChar', pattern(xmlp.XmlGrammar.NAME_START_CHARS));
    def('nameChar', pattern(xmlp.XmlGrammar.NAME_CHARS));

    def('spaces', char(' ').plus());

    def('content', ref('inline'));

    def('inline', ref('spaces')
        .seq(_newLine.neg()
            .star()
            .flatten())
        .pick(1));

  }

}
