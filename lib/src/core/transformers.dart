part of core;

const INDENT = const _Holder('indent');
const UNDENT = const _Holder('undent');

class _Holder {
  final String value;
  const _Holder(this.value);
  String toString() => '* $value *';
}

/**
 * Items can only be:
 * an instance of [String]
 * [INDENT]
 * [UNDENT]
 * Nothing else.
 */
Walker<dynamic, Block> tokensToBlocks() {
  final builder = new _BlockBuilder();
  bool empty = true;

  return new Walker<dynamic, Block>(
      handleData: (dynamic data, EventSink<Block> sink) {
        empty = false;

        var block = builder.build(data);
        if(block != null) {
          sink.add(block);
        }
      },
      handleDone: (EventSink<Block> sink) {
        assert(!builder._finished);

        if(!empty) {
          var block = builder.build(UNDENT);

          // only one case where the return value here is null
          // iif the input stream was empty...right?
          assert(block != null);

          sink.add(block);
        }
        sink.close();
      });
}

class _BlockBuilder {
  String _head;
  _BlockBuilder _builder;
  List<Block> _childBlocks;
  bool _finished = false;

  Block build(dynamic data) {
    assert(!_finished);
    if(_head == null) {
      assert(_builder == null);
      assert(data is String);
      _head = data;
    } else if(_builder == null) {
      if(data == INDENT) {
        _builder = new _BlockBuilder();
      } else {
        var block = new Block(_head, _childBlocks);
        if(data == UNDENT) {
          _finished = true;
        } else {
          _head = data;
          _childBlocks = null;
        }
        return block;
      }
    } else {
      var block = _builder.build(data);

      if(block == null) {
        assert(!_builder._finished);
        return null;
      }

      if(_childBlocks == null) {
        _childBlocks = new List<Block>();
      }
      _childBlocks.add(block);

      if(_builder._finished) {
        _builder = null;
      }
    }
  }
}

/**
 * The resulting tokes are one of:
 *
 * [String], [INDENT], or [UNDENT].
 */
Walker<IndentLine, dynamic> indentsToTokens() {
  int lastLevel = null;
  return new Walker<IndentLine, dynamic>(
      handleData: (IndentLine data, EventSink<dynamic> sink) {
        assert(data != null);
        assert(lastLevel != null || data.level == 0);
        if(lastLevel == null) {
          lastLevel = 0;
        }

        if(data.level > lastLevel) {
          assert(data.level - lastLevel == 1);
          sink.add(INDENT);
        } else {
          while(data.level < lastLevel) {
            sink.add(UNDENT);
            lastLevel--;
          }
        }

        sink.add(data.value);
        lastLevel = data.level;
      },
      handleDone: (EventSink<dynamic> sink) {
        if(lastLevel != null) {
          while(lastLevel > 0) {
            sink.add(UNDENT);
            lastLevel--;
          }
        }
        sink.close();
      });
}

Walker<String, IndentLine> linesToIndents() {
  int _indentUnit;
  int _indentRepeat;

  return new Walker<String, IndentLine>(
      handleData: (String data, EventSink<IndentLine> sink) {
        assert(data != null);

        final line = IndentLine.parse(data, _indentUnit, _indentRepeat);
        if(_indentUnit == null && line is _IndentLinePlus) {
          assert(_indentRepeat == null);
          assert(line.level == 1);
          _indentUnit = line.indentUnit;
          _indentRepeat = line.indentRepeat;
        }
        sink.add(line);

      });
}

Walker<String, String> stringToLines() {
  var remainder = null;
  return new Walker<String, String>(
      handleData: (String data, EventSink<String> sink) {
        assert(data != null);
        final reader = new StringLineReader(data);
        while(true) {
          var line = reader.readNextLine();
          assert(line != null);
          if(remainder != null) {
            line = remainder + line;
            remainder = null;
          }
          if(reader.eof) {
            remainder = line;
            break;
          } else {
            sink.add(line);
          }
        }
      },
      handleDone: (EventSink<String> sink) {
        assert(remainder == null || remainder.isEmpty);
        sink.close();
      }
  );
}


