library test.block_parser;

import 'package:unittest/unittest.dart';
import 'package:okoboji/haml.dart';
import 'package:bot/bot.dart';

void main() {
  group('block parser', () {

    test('blank to empty', () {
      final blocks = Block.getBlocks('').toList();
      expect(blocks, isEmpty);
    });

    test('just hello', () {
      final blocks = Block.getBlocks('hello').toList();
      expect(blocks, hasLength(1));
      final block = blocks.single;
      expect(block.header, equals('hello'));
      expect(block.children, isEmpty);
    });

    test('two lines', () {
      final source = 'hello\ngoodbye\nlater';

      final blocks = Block.getBlocks(source).toList();
      expect(blocks, hasLength(3));

      var block = blocks[0];
      expect(block.header, equals('hello'));
      expect(block.children, isEmpty);

      block = blocks[1];
      expect(block.header, equals('goodbye'));
      expect(block.children, isEmpty);

      block = blocks[2];
      expect(block.header, equals('later'));
      expect(block.children, isEmpty);
    });

    test('simple nesting', () {
      final source = 'hello\n  hi\nlater\n  goodbye';

      final blocks = Block.getBlocks(source).toList();
      expect(blocks, hasLength(2));

      expect(blocks[0].header, equals('hello'));
      expect(blocks[0].children, hasLength(1));
      expect(blocks[0].children[0].header, equals('hi'));
      expect(blocks[0].children[0].children, isEmpty);
      expect(blocks[1].header, equals('later'));
      expect(blocks[1].children, hasLength(1));
      expect(blocks[1].children[0].header, equals('goodbye'));
      expect(blocks[1].children[0].children, isEmpty);
    });

    test('3 levels', () {
      final source = '''hello\n  hi\n    goodbye''';

      final blocks = Block.getBlocks(source).toList();
      expect(blocks, hasLength(1));

      expect(blocks[0].header, equals('hello'));
      expect(blocks[0].children, hasLength(1));
      expect(blocks[0].children[0].header, equals('hi'));
      expect(blocks[0].children[0].children, hasLength(1));
      expect(blocks[0].children[0].children[0].header, equals('goodbye'));
      expect(blocks[0].children[0].children[0].children, isEmpty);
    });

    group('invalid', () {
      _invalid.forEach((key, value) {
        test(key, () {
          expect(() => Block.getBlocks(value).toList(), throws);
        });
      });
    });

    group('valid', () {
      _valid.forEach((key, value) {
        test(key, () {
          expect(() => Block.getBlocks(value).toList(), returnsNormally);
        });
      });
    });
  });

}

const _valid = const {
  'empty string': '',
  'new lines': '\n\n',
  '3 levels, with blanks': '''

hello
  tom

    test

  cool

beans

now

'''
};

const _invalid = const {
  'null': null,
  'starts with whitespace': ' hello',
  'mixed tabs and spaces': '''
hello
  two spaces
\ttab''',
  'inconsistent indent': '''
hello
  two spaces - ok
   three spaces - bad!
''',
  'inconsistent indent2': '''
hello
  two spaces - ok
     three spaces - bad!
'''
};
