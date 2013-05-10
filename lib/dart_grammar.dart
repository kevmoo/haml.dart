library dart_grammar;

import 'package:bot/bot.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/dart.dart';

final _parserInstance = new DartParser();

final Parser dartExpression = _parserInstance['simple-expression'];
final Parser dartIdentifier = _parserInstance['identifier'];

class DartParser extends DartGrammar {
  void initialize() {
    super.initialize();

    def('simple-expression', ref('literal'));

    redef('numericLiteral', (parser) => parser.flatten());

    action('singleLineString', (List value) {
      if(value.length == 3) {
        assert(value[0] is Token);
        assert(value[2] is Token);

        if(value[0].value == value[2].value) {
          if(value[0].value == '"' || value[0].value == "'") {
            assert(value[1] is List);
            var values = value[1];

            // TODO: should make darn sure all the children are chars, right?
            assert(values .every((f) => f is String));

            return values.join();
          }
        }
      }
      return value;
    });

    action('stringLiteral', (List value) {
      assert(value.length >= 1);

      if(value.every((e) => e is String)) {
        return value.join();
      }

      return value;
    });

    action('nullLiteral', (Token value) {
      assert(value.value == 'null');
      return null;
    });

    action('booleanLiteral', (Token value) {
      switch(value.value) {
        case 'true':
          return true;
        case 'false':
          return false;
        default:
          throw 'boo! $token.value';
      }
    });

    action('numericLiteral', (value) {
      print(value);
      try {
        return int.parse(value);
      } on FormatException catch (e) {
        return double.parse(value);
      }
    });
  }

}


typedef dynamic ExpressionEvaluator(InlineExpression exp);

class LiteralExpression implements InlineExpression {
  final dynamic value;

  LiteralExpression._internal(String expression, this.value) :
    super(expression);
}

class InlineExpression {
  final String expression;

  InlineExpression(this.expression) {
    assert(dartExpression.accept(expression));
  }

  String toString() => 'InlineExpression: $expression';

  static ExpressionEvaluator getEvaluatorFromMap(Map<String, String> map) {
    requireArgumentNotNull(map, 'map');

    map.keys.forEach((String k) {
      if(!dartIdentifier.accept(k)) {
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

    return (InlineExpression val) => evaluate(val.expression, eval);
  }

  static dynamic evaluate(String expression, [dynamic lookup(String val)]) {
    final result = dartExpression.parse(expression);

    if(result.isSuccess) {
      return result.value;
    } else {
      print([result, result.value, result.result, result.message]);
    }

    if(lookup != null) {
      return lookup(expression);
    }

    throw 'Could not evaluate expression "${expression}"';
  }

  static final _reservedValues = ['true', 'false'].toSet();
}
