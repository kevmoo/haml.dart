part of html;

class HtmlFormat {
  static const HtmlFormat HTML5 = const HtmlFormat._internal('html5');
  static const HtmlFormat HTML4 = const HtmlFormat._internal('html4');
  static const HtmlFormat XHTML = const HtmlFormat._internal('xhtml');

  final String name;

  static const _formats = const[HTML5, HTML4, XHTML];

  String toString() => 'HtmlFormat $name';

  const HtmlFormat._internal(this.name);

  static HtmlFormat parse(String input) {
    return _formats.singleWhere((f) => f.name == input);
  }
}
