library block;

import 'dart:async';
import 'package:bot/bot.dart';
import 'package:petitparser/petitparser.dart';

part 'src/block/grammar.dart';
part 'src/block/line.dart';
part 'src/block/parser.dart';
part 'src/block/transformers.dart';

final _indentUnit = '+'.codeUnits.single;
final _undentUnit = '-'.codeUnits.single;

class Block {
  final String header;
  final Sequence<Block> children;

  Block(this.header, [Iterable<Block> items = null]) :
    this.children = new ReadOnlyCollection(items == null ? [] : items) {
    requireArgumentNotNullOrEmpty(header, 'header');
    assert(!Line.isWhite(header.codeUnits.first));

    // TODO: we might have a model for comments, which makes headers
    // multi-line. But for now...
    assert(!header.contains('\n'));
    assert(!header.contains('\r'));

    assert(children != null);
    assert(children.every((b) => b is Block));
  }

  bool operator ==(other) {
    return other is Block && other.header == this.header &&
        this.children.itemsEqual(other.children);
  }

  int getTotalCount() {
    return children.fold(1, (int val, Block child) {
      return val + child.getTotalCount();
    });
  }

  static String getPrefixedString(Iterable<Block> blocks) {
    final buffer = new StringBuffer();
    blocks.forEach((b) => b.writePrefixedString(buffer));
    return buffer.toString();
  }

  void writePrefixedString(StringSink buffer) {
    // if the header is entirely indent/undent chars, then double them
    String val;
    if(header.codeUnits.every((u) => u == _indentUnit)) {
      // TODO!!
      throw 'not impld';
    } else if(header.codeUnits.every((u) => u == _undentUnit)) {
      // TODO!!
      throw 'not impld';
    } else {
      val = header;
    }
    buffer.writeln(val);
    if(!children.isEmpty) {
      buffer.writeCharCode(_indentUnit);
      buffer.writeln();
      children.forEach((b) => b.writePrefixedString(buffer));
      buffer.writeCharCode(_undentUnit);
      buffer.writeln();
    }
  }

  static Iterable<Block> getBlocks(String source) {
    assert(source != null);

    return new _BlockIterable(source);
  }

  static String getString(Iterable<Block> blocks, {int indentUnit,
    int indentCount: 2}) {
    final buffer = new StringBuffer();
    writeBlocks(buffer, blocks, indentUnit: indentUnit,
        indentCount: indentCount);
    return buffer.toString();
  }

  static void writeBlocks(StringSink buffer, Iterable<Block> blocks, {
    int level: 0, int indentUnit, int indentCount: 2}) {
    assert(level >= 0);
    if(indentUnit == null) {
      indentUnit = Line._space;
    }
    assert(Line.isWhite(indentUnit));
    assert(indentCount > 0);

    for(Block b in blocks) {
      for(var i = 0; i < level * indentCount; i++) {
        buffer.writeCharCode(indentUnit);
      }

      buffer.writeln(b.header);
      writeBlocks(buffer, b.children,
          level: level + 1, indentUnit: indentUnit, indentCount: indentCount);
    }
  }
}

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
