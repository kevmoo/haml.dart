part of core;

class _IndentLinePlus extends IndentLine {
  final int indentUnit;
  final int indentRepeat;

  _IndentLinePlus(String value, this.indentUnit, this.indentRepeat) :
    super(1, value) {
    assert(IndentLine.isWhite(indentUnit));
    assert(indentRepeat > 0);
  }
}

class IndentLine {
  final int level;
  final String value;

  IndentLine(this.level, this.value) {
    assert(level >= 0);
    assert(value != null);
    assert(!value.isEmpty);
    assert(value.codeUnitAt(0) != _tab);
    assert(value.codeUnitAt(0) != _space);
  }

  const IndentLine.empty() : this.level = null, this.value = '';

  String toString() => '$level\t$value';

  static IndentLine parse(String line, int indentUnit, int indentRepeat) {
    if(line == null) return null;
    if(line.isEmpty) return const IndentLine.empty();

    if(indentUnit == null) {
      if(isWhite(line.codeUnits.first)) {
        // this could be bad. If the rest of the string isn't white, then throw!
        if(line.codeUnits.every(isWhite)) {
          return const IndentLine.empty();
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

        return new _IndentLinePlus(line.substring(indentRepeat), indentUnit, indentRepeat);
      }
      return new IndentLine(0, line);
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

      return new IndentLine(level, line.substring(indent.length));
    }

    throw 'should never get here...right?';
  }

  static bool isWhite(int unit) => unit == _tab || unit == _space;

  static final int _tab = '\t'.codeUnits.single;
  static final int _space = ' '.codeUnits.single;
}
