library test.block_parser;

import 'dart:math' as math;
import 'package:petitparser/petitparser.dart';
import 'package:unittest/unittest.dart';

import 'package:okoboji/core.dart';

import '../test_shared.dart';

final _rnd = new math.Random();

void main() {

  final jsonValue = getHamlSpecTests();

  group('haml samples', () {
    jsonValue.forEach((groupName, Map<String, Map> testMap) {
      group(groupName, () {

        testMap.forEach((String key, Map testData) {
          if(key == 'a multiply nested silent comment with inconsistent indents') {
            // TODO: need to handle -# comments with inconsistent indents
            return;
          }

          final String value = testData['haml'];

          _multiRoundTrip(key, value);
        });

      });
    });
  });

  group('block parser', () {

    test('block equality', () {
      var block1 = new Block.raw('a', []);
      expect(block1, equals(block1));
      expect(block1, same(block1));

      var block2 = new Block.raw('a', []);
      expect(block2, equals(block1));
      expect(block2, isNot(same(block1)));

      var block3 = new Block.raw('test', [new Block.raw('val', [])]);
      var block4 = new Block.raw('test', [new Block.raw('val', [])]);
      expect(block3, equals(block4));

      var block5 = new Block.raw('test', [new Block.raw('val2', [])]);
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
        _multiRoundTrip(key, value);
      });
    });
  });
}

final _spaceCodeUnit = ' '.codeUnits.single;
final _tabCodeUnit = '\t'.codeUnits.single;

void _multiRoundTrip(String name, String value) {
  group(name, () {
    test('getBlocks', () {
      expect(() => Block.getBlocks(value).toList(), returnsNormally);
    });

    var char = ['tab','space'].elementAt(_rnd.nextInt(2));
    var count = _rnd.nextInt(3) + 1;

    test('roundtrip $char x $count', () {
      var charUnit = char == 'tab' ? _tabCodeUnit : _spaceCodeUnit;
      _roundTrip(value, charUnit, count);
    });

    test('entry stream', () {
      final walker = stringToEntries();
      final val = walker.single(value).toList();
      // TODO: actual validation here?
      // round trip? Hmm...
    });
  });
}

void _roundTrip(String value, int indentUnit, int indentCount) {
  final blocks = Block.getBlocks(value).toList();
  final newValue = Block.getString(blocks, indentUnit: indentUnit,
      indentCount: indentCount);

  final blockCopy = Block.getBlocks(newValue).toList();

  expect(blockCopy, orderedEquals(blocks));
}

const _valid = const {
  'hello': 'hello',
  'empty string': '',
  'new lines': '\n\n',
  'simple outline': '''
1
 1.1
 1.2
  1.2.1
2
3
4
 4.1
  4.1.1
   4.1.1.1
  4.1.2
 4.2
5  
''',
  '2 levels, simple': '''
level1
  level2
''',
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
