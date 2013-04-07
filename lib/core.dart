library core;

import 'dart:async';
import 'package:bot/bot.dart';
import 'package:petitparser/petitparser.dart';

part 'src/core/block.dart';
part 'src/core/grammar.dart';
part 'src/core/indent_line.dart';
part 'src/core/parser.dart';
part 'src/core/transformers.dart';
part 'src/core/walker.dart';

final _indentUnit = '+'.codeUnits.single;
final _undentUnit = '-'.codeUnits.single;

class LineIterable extends Iterable<Line> {
  final String source;

  LineIterable(this.source);

  Iterator<Line> get iterator => new LineIterator(source);
}

class LineIterator extends Iterator<Line> {
  final StringLineReader _reader;

  int _indentUnit;
  int _indentRepeat;

  Line _current;

  LineIterator(String source) : this._reader = new StringLineReader(source);

  Line get current => _current;

  Line peek() {
    // We skip blank lines. Where line.level == null
    while(true) {
      final value = _reader.peekNextLine();
      final line = _process(value);

      if(line == null) {
        return null;
      } else if(line.level == null) {
        _reader.readNextLine();
      } else {
        return line;
      }
    }
  }

  bool moveNext() {
    // We skip blank lines. Where line.level == null
    do {
      var line = _reader.readNextLine();
      _current = _process(line);
    } while(_current != null && _current.level == null);

    return _current != null;
  }

  Line _process(String value) {
    final line = Line.parse(value, _indentUnit, _indentRepeat);
    if(_indentUnit == null && line is _LinePlus) {
      assert(_indentRepeat == null);
      assert(line.level == 1);
      _indentUnit = line.indentUnit;
      _indentRepeat = line.indentRepeat;
    }
    return line;
  }
}

class _BlockIterable extends Iterable<Block> {
  final LineIterable source;

  _BlockIterable(String value) : source = new LineIterable(value);

  Iterator<Block> get iterator => new _BlockIterator(source);
}

class _OnceIterable<E> extends Iterable<E> {
  final Iterator<E> _value;
  bool _requested = false;

  _OnceIterable(this._value);

  Iterator<E> get iterator {
    require(!_requested, 'Can only be iterated once!');
    _requested = true;
    return _value;
  }

}

class _BlockIterator extends Iterator<Block> {
  final LineIterator reader;
  final int level;
  Block _current;
  bool _done = false;

  _BlockIterator(LineIterable source) :
    this.reader = source.iterator, this.level = 0;

  _BlockIterator.child(this.reader, this.level) {
    // child iterators should not be at level 0
    assert(level > 0);
  }

  Block get current => _current;

  bool moveNext() {
    if (!_done && reader.moveNext()) {
      var currentLine = reader.current;

      assert(currentLine.level == level);

      var nextLine = reader.peek();

      // if the next line is the same level, then we have a blank block
      if(nextLine == null || nextLine.level == level) {
        _current = new Block(currentLine.value, []);
        return true;
      } else if(nextLine.level < level) {
        _current = new Block(currentLine.value, []);
        _done = true;
        return true;
      } else if(nextLine.level == level + 1) {
        // we are indenting, eh?
        final childIterator = new _BlockIterator.child(reader, level + 1);
        final childIterable = new _OnceIterable(childIterator);

        _current = new Block(currentLine.value, childIterable);

        // child iteration has completed at this point.
        // It's possible that the next item is at or below the current level
        // if the next item is below the curent level, we're done here
        nextLine = reader.peek();
        if(nextLine != null && nextLine.level < level) {
          _done = true;
        }

        return true;
      }
      assert(nextLine.level > (level + 1));
      throw 'next level is indented too much';
    }
    return false;
  }
}
