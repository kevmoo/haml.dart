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

    final eval = (String expression) {
      if(map.containsKey(expression)) {
        return map[expression];
      }
      throw 'could not find "$expression"';
    };

    return (InlineExpression val) => evaluate(val.value, eval);
  }

  static dynamic evaluate(String expression, [dynamic lookup(String val)]) {
    switch(expression) {
      case 'true':
        return true;
      case 'false':
        return false;
    }

    if(dart_grammar.dartNumber.accept(expression)) {
      try {
        return int.parse(expression);
      } on FormatException catch (e) {
        return double.parse(expression);
      }
    }

    if(lookup != null) {
      return lookup(expression);
    }

    throw 'Could not evaluate expression "${expression}"';
  }

  static final _reservedValues = ['true', 'false'].toSet();
}
