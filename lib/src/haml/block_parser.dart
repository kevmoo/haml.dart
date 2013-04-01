part of haml;

class Block {
  final String header;
  final Sequence<Block> children;

  Block(this.header, Iterable<Block> items) :
    this.children = new ReadOnlyCollection(items) {
    assert(header != null);
    assert(children != null);
    assert(children.every((b) => b != null));
  }

  bool operator ==(other) {
    return other is Block && other.header == this.header &&
        this.children.itemsEqual(other.children);
  }

  static Iterable<Block> getBlocks(String source) {
    assert(source != null);

    return new _BlockIterable(source);
  }
}

class _LineIterable extends Iterable<_Line> {
  final String source;

  _LineIterable(this.source);

  Iterator<_Line> get iterator => new _LineIterator(source);
}

class _LineIterator extends Iterator<_Line> {
  final StringLineReader _reader;

  int _indentUnit;
  int _indentRepeat;

  _Line _current;

  _LineIterator(String source) : this._reader = new StringLineReader(source);

  _Line get current => _current;

  _Line peek() {
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

    // if _current has an empty value and we're at the end of the reader
    // this this is a throw-away final, empty line. Just call it done.
    if(_current != null && _current.value.isEmpty && _reader.eof) {
      _current = null;
    }
    return _current != null;
  }

  _Line _process(String value) {
    final line = _Line.parse(value, _indentUnit, _indentRepeat);
    if(_indentUnit == null && line is _LinePlus) {
      assert(_indentRepeat == null);
      assert(line.level == 1);
      _indentUnit = line.indentUnit;
      _indentRepeat = line.indentRepeat;
    }
    return line;
  }
}

class _LinePlus extends _Line {
  final int indentUnit;
  final int indentRepeat;

  _LinePlus(String value, this.indentUnit, this.indentRepeat) :
    super(1, value) {
    assert(_Line.isWhite(indentUnit));
    assert(indentRepeat > 0);
  }
}

class _Line {
  final int level;
  final String value;

  _Line(this.level, this.value) {
    assert(level >= 0);
    assert(value != null);
    assert(!value.isEmpty);
    assert(value.codeUnitAt(0) != _tab);
    assert(value.codeUnitAt(0) != _space);
  }

  const _Line.empty() : this.level = null, this.value = '';

  String toString() => '$level\t$value';

  static _Line parse(String line, int indentUnit, int indentRepeat) {
    if(line == null) return null;
    if(line.isEmpty) return const _Line.empty();

    if(indentUnit == null) {
      if(isWhite(line.codeUnits.first)) {
        // this could be bad. If the rest of the string isn't white, then throw!
        if(line.codeUnits.every(isWhite)) {
          return const _Line.empty();
        }
        assert(indentRepeat == null);

        // entering a new world.
        // We are going to try to infer what the indent type and repeat is
        // it might be invalid. We'll see.
        indentRepeat = 0;
        for(final unit in line.codeUnits) {
          if(indentUnit == null) {
            // this is the first character. We proved earlier that it must
            // be whitespace, right?
            assert(isWhite(unit));
            if(unit == _space) {
              indentUnit = _space;
            } else {
              assert(unit == _tab);
              indentUnit = _tab;
            }
          } else if(!isWhite(unit)) {
            // we're out of whitespace. indentRepeat is valid
            break;
          } else if(unit != indentUnit) {
            // we have mixed chars for indent. Bad!
            throw 'mixed characters for indent is bad...';
          }

          indentRepeat++;
        }

        return new _LinePlus(line.substring(indentRepeat), indentUnit, indentRepeat);
      }
      return new _Line(0, line);
    } else {
      // so we have a level, which means
      assert(isWhite(indentUnit));
      assert(indentRepeat > 0);

      final indent = new String
          .fromCharCodes(line.codeUnits.takeWhile((u) => u == indentUnit));

      assert(line.codeUnitAt(indent.length) != indentUnit);
      if(isWhite(line.codeUnitAt(indent.length))) {
        throw 'mixed whitespace indent...bad!';
      }

      final mod = indent.length % indentRepeat;
      if(mod != 0) {
        throw 'inconsistent indention, fool!';
      }

      final level = indent.length ~/ indentRepeat;

      return new _Line(level, line.substring(indent.length));
    }

    throw 'should never get here...right?';
  }

  static bool isWhite(int unit) => unit == _tab || unit == _space;

  static final int _tab = '\t'.codeUnits.single;
  static final int _space = ' '.codeUnits.single;
}

class _BlockIterable extends Iterable<Block> {
  final _LineIterable source;

  _BlockIterable(String value) : source = new _LineIterable(value);

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
  final _LineIterator reader;
  final int level;
  Block _current;
  bool _done = false;

  _BlockIterator(_LineIterable source) :
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

      final nextLine = reader.peek();

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
        return true;
      }
      assert(nextLine.level > (level + 1));
      throw 'next level is indented too much';
    }
    return false;
  }
}
