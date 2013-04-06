part of block;

const INDENT = const _Holder('indent');
const UNDENT = const _Holder('undent');

class _Holder {
  final String value;
  const _Holder(this.value);
  String toString() => '* $value *';
}

StreamTransformer<_Line, dynamic> toFlat() {
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
        print(data);

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


