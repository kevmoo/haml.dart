library test.block_parser;

import 'package:unittest/unittest.dart';
import 'package:okoboji/haml.dart';
import 'package:bot/bot.dart';

void main() {
  group('block parser', () {

    test('block equality', () {
      var block1 = new Block('', []);
      expect(block1, equals(block1));
      expect(block1, same(block1));

      var block2 = new Block('', []);
      expect(block2, equals(block1));
      expect(block2, isNot(same(block1)));

      var block3 = new Block('test', [new Block('val', [])]);
      var block4 = new Block('test', [new Block('val', [])]);
      expect(block3, equals(block4));

      var block5 = new Block('test', [new Block('val2', [])]);
      expect(block5, isNot(equals(block3)));
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

    group('valid', () {
      _valid.forEach((key, value) {
        test(key, () {
          expect(() => Block.getBlocks(value).toList(), returnsNormally);
        });

        group('roundtrip: $key', () {
          final blocks = Block.getBlocks(value).toList();
          _multiRoundTrip(blocks);
        });
      });
    });
  });

}

void _multiRoundTrip(List<Block> blocks) {
  test('space x 2', () {
    _roundTrip(blocks, ' '.codeUnits.single, 2);
  });
  test('space x 1', () {
    _roundTrip(blocks, ' '.codeUnits.single, 1);
  });
  test('tab x 1', () {
    _roundTrip(blocks, '\t'.codeUnits.single, 1);
  });
  test('tab x 3', () {
    _roundTrip(blocks, '\t'.codeUnits.single, 3);
  });
}

void _roundTrip(List<Block> blocks, int indentUnit, int indentCount) {
  final value = Block.getString(blocks, indentUnit: indentUnit,
      indentCount: indentCount);

  final blockCopy = Block.getBlocks(value).toList();

  expect(blockCopy, orderedEquals(blocks));
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
