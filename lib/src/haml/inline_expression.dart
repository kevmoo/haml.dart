part of haml;

typedef dynamic ExpressionEvaluator(InlineExpression exp);

class InlineExpression {
  final String value;

  InlineExpression(this.value) {
    assert(HamlEntityGrammar.unquotedValue.accept(value));
  }

  String toString() => 'VariableReference: $value';

  static ExpressionEvaluator getEvaluatorFromMap(Map<String, String> map) {
    requireArgumentNotNull(map, 'map');

    map.keys.forEach((String k) {
      if(!dart_grammar.dartIdentifier.accept(k)) {
        throw new ArgumentError('Provided key "$k" is not a valid identifier');
      }
    });

    final reservedIntersect = map.keys.toSet().intersection(_reservedValues);
    if(!reservedIntersect.isEmpty) {
      throw new ArgumentError('map contains reserved values: ' +
          reservedIntersect.join(', '));
    }

    return (InlineExpression val) {
      switch(val.value) {
        case 'true':
          return true;
        case 'false':
          return false;
      }

      final String result = map[val.value];

      if(result != null) {
        return result;
      }

      if(dart_grammar.dartNumber.accept(val.value)) {
        try {
          return int.parse(val.value);
        } on FormatException catch (e) {
          return double.parse(val.value);
        }
      }

      throw 'Could not evaluate expression "${val.value}"';
    };
  }

  static final _reservedValues = ['true', 'false'].toSet();
}
