part of block;

const INDENT = const _Holder('indent');
const UNDENT = const _Holder('undent');

const _EOF = const _Holder('EOF');

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
StreamTransformer<dynamic, Block> toBlocks() {
  final builder = new _BlockBuilder();

  return new StreamTransformer<dynamic, Block>(
      handleData: (dynamic data, EventSink<Block> sink) {
        log(data.toString(), AnsiColor.BLUE);
        var block = builder.build(data);
        if(block != null) {
          sink.add(block);
        }
      },
      handleDone: (EventSink<Block> sink) {
        assert(!builder.finished);
        print('final undent');

        try{
          var block = builder.build(_EOF);
          // only one case where the return value here is null
          // iif the input stream was empty...right?
          if(block != null) {
            sink.add(block);
          }
        } catch (e, s) {
          print("oops! $e $s");
        } finally {
          sink.close();
        }
      });
}

class _BlockBuilder {
  static int _idCount = 0;

  final int _id;
  String _head;
  _BlockBuilder _builder;
  List<Block> _childBlocks;
  bool finished = false;

  void _log(String value) {
    log([_id, value]);
  }

  _BlockBuilder() : _id = _idCount++ {
    _log('new Builder');
  }

  Block build(dynamic data) {
    _log("ello...");
    assert(!finished);
    if(_head == null) {
      assert(_builder == null);
      assert(data is String);
      _log('new head: $data');
      _head = data;
    } else if(_builder == null) {
      if(data == INDENT) {
        _log('indent!');
        _builder = new _BlockBuilder();
      } else if(data == UNDENT) {
        _log('undent - builder is finished');
        finished = true;
        if(_childBlocks == null) {
          _childBlocks = [];
        }
        return new Block(_head, _childBlocks);
      } else if(data == _EOF) {
        _log('EOF...clear out');
        try {
          return new Block(_head, []);
        } finally {
          finished = true;
        }
      } else {
        _log('throw out the last guy: $data');
        try {
          if(_childBlocks == null) {
            _childBlocks = [];
          }
          return new Block(_head, _childBlocks);
        } finally {
          _childBlocks = null;
          _head = data;
        }
      }
    } else {
      _log('pushing data to child: $data');
      var block = _builder.build(data);
      _log('data: $data \t block: $block');
      if(block != null) {
        if(_childBlocks == null) {
          _childBlocks = new List<Block>();
        }
        _childBlocks.add(block);
        if(_builder.finished) {
          _log("builder finishing, next round should undent, right?");
          _builder = null;
        }

        if(data == _EOF) {
          // let's clear out now
          try {
            _log('clearing out EOF');
            return new Block(_head, _childBlocks);
          } finally {
            finished = true;
          }
        }
      } else {
        assert(!_builder.finished);
      }
    }
  }
}


StreamTransformer<Line, dynamic> toFlat() {
  int lastLevel = null;
  return new StreamTransformer<Line, dynamic>(
      handleData: (Line data, EventSink<dynamic> sink) {
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
      });
}

StreamTransformer<String, Line> toLines() {
  int _indentUnit;
  int _indentRepeat;

  return new StreamTransformer<String, Line>(
      handleData: (String data, EventSink<Line> sink) {
        assert(data != null);

        final line = Line.parse(data, _indentUnit, _indentRepeat);
        if(_indentUnit == null && line is _LinePlus) {
          assert(_indentRepeat == null);
          assert(line.level == 1);
          _indentUnit = line.indentUnit;
          _indentRepeat = line.indentRepeat;
        }
        sink.add(line);

      });
}

StreamTransformer<String, String> splitLines() {
  var remainder = null;
  return new StreamTransformer<String, String>(
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


