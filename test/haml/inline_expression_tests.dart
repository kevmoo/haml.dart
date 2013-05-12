part of test.haml;

void _registerInlineExpressionTests() {
  group('evaluate', () {
    EXPRESSIONS.forEach((k, v) {
      test(k, () {
        var result = new dart.InlineExpression(k);
        expect(result.value, equals(v));
      });
    });
  });
}
