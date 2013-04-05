library test.block_parser;

import 'dart:io';
import 'dart:json' as json;
import 'package:petitparser/petitparser.dart';
import 'package:unittest/unittest.dart';
import 'package:pathos/path.dart' as pathos;

import 'package:okoboji/block.dart';

const _jsonTestPath = 'test/haml-spec/tests.json';

void main() {

  final jsonFile = new File(pathos.normalize(_jsonTestPath));

  final Map<String, Map> jsonValue = json.parse(jsonFile.readAsStringSync());

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
      var block1 = new Block('a', []);
      expect(block1, equals(block1));
      expect(block1, same(block1));

      var block2 = new Block('a', []);
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
        _multiRoundTrip(key, value);
      });
    });
  });
}

void _testPrefixGrammar(String value) {
  final blocks = Block.getBlocks(value).toList();

  /*
  print('*old blocks');
  print(blocks);
  print(Error.safeToString(Block.getString(blocks)));
  */

  final prefixedVal = Block.getPrefixedString(blocks);

  final grammar = new BlockParser();
  Result thing = grammar.parse(prefixedVal);

  if(thing is Failure) {
    String buffer = thing.buffer;
    if(buffer.startsWith('-#')) {
      // TODO: support comments!
      print('Ignoring comments for now.');
      return;
    }
    fail(thing.toString());
  }

  List<Block> newBlocks = thing.result;

  /*
  print('*new blocks');
  print(newBlocks);
  print(Error.safeToString(Block.getString(newBlocks)));
  */

  expect(newBlocks, orderedEquals(blocks));
}

void _multiRoundTrip(String name, String value) {
  group(name, () {
    test('getBlocks', () {
      expect(() => Block.getBlocks(value).toList(), returnsNormally);
    });
    group('roundtrip', () {
      test('space x 2', () {
        _roundTrip(value, ' '.codeUnits.single, 2);
      });
      test('space x 1', () {
        _roundTrip(value, ' '.codeUnits.single, 1);
      });
      test('tab x 1', () {
        _roundTrip(value, '\t'.codeUnits.single, 1);
      });
      test('tab x 3', () {
        _roundTrip(value, '\t'.codeUnits.single, 3);
      });
    });
    test('prefix grammar', () {
      _testPrefixGrammar(value);
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
