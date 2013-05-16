part of html;

class HamlFormat {
  static const HamlFormat HTML5 = const HamlFormat._internal('html5');
  static const HamlFormat HTML4 = const HamlFormat._internal('html4');
  static const HamlFormat XHTML = const HamlFormat._internal('xhtml');

  final String name;

  static const _formats = const[HTML5, HTML4, XHTML];

  String toString() => 'HamlFormat $name';

  const HamlFormat._internal(this.name);

  static HamlFormat parse(String input) {
    return _formats.singleWhere((f) => f.name == input);
  }
}
