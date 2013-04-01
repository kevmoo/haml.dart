library test.block_parser;

import 'package:unittest/unittest.dart';
import 'package:okoboji/haml.dart';

void main() {
  group('block parser', () {

    test('blank to empty', () {
      final blocks = Block.getBlocks('');
      expect(blocks, isEmpty);
    });

    test('blank to empty', () {
      final blocks = Block.getBlocks('hello').toList();
      expect(blocks, hasLength(1));
      final block = blocks.single;
      expect(block.header, equals('hello'));
      expect(block.children, isEmpty);
    });

  });

}

const _invalid = const {
  'null': null,
  'starts with whitespace': ' hello',
  'mixed tabs and spaces': '''
hello
  two spaces
\ttab''',
};
