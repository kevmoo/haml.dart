part of test.haml;

void _registerInlineExpressionTests() {
  group('evaluate', () {
    EXPRESSIONS.forEach((k, v) {
      test(k, () {
        var result = dart.InlineExpression.evaluate(k);
        expect(result, equals(v));
      });
    });
  });
}
