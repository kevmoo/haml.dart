library test.block_parser;

import 'package:unittest/unittest.dart';
import 'package:okoboji/haml.dart';
import 'package:bot/bot.dart';

void main() {
  group('block parser', () {

    test('runes and code units and spaces and tabs', () {
      final spaceTab = ' \t';
      expect(spaceTab, hasLength(2));
      expect(spaceTab.codeUnits, hasLength(2));
      expect(spaceTab.runes, hasLength(2));

      expect(3 % 2, equals(1));
      expect(3 % 1, equals(0));
      expect(3 % 3, equals(0));
      expect(3 % 4, equals(3));
      expect(3 % 5, equals(3));
      expect(3 % 6, equals(3));
    });

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
  });

}

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
'''
};
