part of core;

class BlockGrammar extends CompositeParser {

  static final _indentStr = new String.fromCharCode(_indentUnit);
  static final _undentStr = new String.fromCharCode(_undentUnit);

  static final _newLine = Token.newlineParser();

  void initialize() {
    def('start', ref('block').star().end());

    def('block', ref('header').seq(
        ref('indent-line')
        .seq(ref('block').plus())
        .seq(ref('undent-line'))
        .pick(1)
        .optional()
        ));

    def('header', ref('indent').or(ref('undent')).neg()
        .seq(ref('line')).flatten()
        .seq(_newLine)
        .pick(0));

    def('line', _newLine.neg().star().flatten());

    def('indent-line', ref('indent').seq(_newLine));
    def('undent-line', ref('undent').seq(_newLine));

    def('indent', char(_indentStr));
    def('undent', char(_undentStr));
  }
}
