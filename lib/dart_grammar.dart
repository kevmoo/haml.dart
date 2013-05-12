library dart_grammar;

import 'package:bot/bot.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/dart.dart';

final _parserInstance = new DartParser();


class DartParser extends DartGrammar {
  static final Parser identifier = _parserInstance['identifier'];

  static final Parser expression = _parserInstance['simple-expression'];

  void initialize() {
    super.initialize();

    def('simple-expression', ref('literal') | ref('identifier'));

    redef('numericLiteral', (parser) => parser.flatten());

    action('singleLineString', (List value) {
      if(value.length == 3) {
        assert(value[0] is Token);
        assert(value[2] is Token);

        if(value[0].value == value[2].value) {
          if(value[0].value == '"' || value[0].value == "'") {
            assert(value[1] is List);
            var values = value[1];

            // TODO: should make darn sure all the children are Strings, right?
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

    action('literal', (dynamic literal) {
      return new LiteralExpression(literal);
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
      try {
        return int.parse(value);
      } on FormatException catch (e) {
        return double.parse(value);
      }
    });

    action('identifier', (Token value) {
      print('identifier: $value');
      return new IdentifierExpression(value.value);
    });
  }

}


typedef dynamic ExpressionEvaluator(InlineExpression exp);

class IdentifierExpression implements InlineExpression {
  final String identifier;

  IdentifierExpression(this.identifier);

  dynamic evaluate(dynamic expressionEvaler(String expressior)) {
    return expressionEvaler(identifier);
  }
}

class LiteralExpression implements InlineExpression {
  final dynamic value;

  LiteralExpression(this.value) {
    assert(value is String ||
        value is bool ||
        value is num ||
        value == null);
  }

  dynamic evaluate(dynamic expressionEvaler(String expressior)) {
    return value;
  }
}

abstract class InlineExpression {

  factory InlineExpression(String source) {
    var result = DartParser.expression.parse(source);
    if(result.isSuccess) {
      return result.value;
    } else {
      throw result;
    }
  }

  static ExpressionEvaluator getEvaluatorFromMap(Map<String, String> map) {
    requireArgumentNotNull(map, 'map');

    map.keys.forEach((String k) {
      if(!DartParser.identifier.accept(k)) {
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

    return (InlineExpression val) => val.evaluate(eval);
  }

  dynamic evaluate(dynamic expressionEvaler(String expressior));

  static final _reservedValues = ['true', 'false'].toSet();
}
