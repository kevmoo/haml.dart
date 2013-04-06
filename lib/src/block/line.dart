part of block;

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
