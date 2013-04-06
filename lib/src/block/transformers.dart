part of block;

const _indent = const _Holder('indent');
const _undent = const _Holder('undent');

class _Holder {
  final String value;
  const _Holder(this.value);
  String toString() => '* $value *';
}

StreamTransformer<_Line, dynamic> toFlat() {
  int lastLevel = null;
  return new StreamTransformer<_Line, dynamic>(
      handleData: (_Line data, EventSink<dynamic> sink) {
        assert(data != null);
        assert(lastLevel != null || data.level == 0);
        if(lastLevel == null) {
          lastLevel = 0;
        }

        if(data.level > lastLevel) {
          assert(data.level - lastLevel == 1);
          sink.add(_indent);
        } else {
          while(data.level < lastLevel) {
            sink.add(_undent);
            lastLevel--;
          }
        }

        sink.add(data.value);
        lastLevel = data.level;
      });
}

StreamTransformer<String, _Line> toLines() {
  int _indentUnit;
  int _indentRepeat;

  return new StreamTransformer<String, _Line>(
      handleData: (String data, EventSink<_Line> sink) {
        assert(data != null);
        print(data);

        final line = _Line.parse(data, _indentUnit, _indentRepeat);
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


