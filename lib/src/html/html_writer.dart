part of html;

class EntryType {
  final String name;

  const EntryType._internal(this.name);

  static const EntryType OTHER = const EntryType._internal('other');
  static const EntryType INDENT = const EntryType._internal('indent');
  static const EntryType EOF = const EntryType._internal('end-of-file');

  static EntryType of(Entry value) {
    if(value == null) {
      return EntryType.EOF;
    } else if(value is EntryIndent) {
      return EntryType.INDENT;
    } else {
      return EntryType.OTHER;
    }
  }
}

Walker<Entry, String> htmlEntryToHtml(
    {
      HtmlFormat format: HtmlFormat.HTML5,
      dart.ExpressionEvaluator eval: null
      }) {

  if(eval == null) {
    eval = (dart.InlineExpression epr) {
      throw 'No expression evaluator provided.';
    };
  }

  void _log (val) => _getLogger('htmlEntryToHtml').log(logging.Level.INFO, val.toString());

  final indentChar = ' ';
  final indentCount = 2;

  final List<HtmlEntry> levels = new List<HtmlEntry>();

  void lookAhead(EventSink<String> sink, Entry current, EntryType nextType) {
    assert(sink != null);
    assert(current != null);

    if(current is EntryIndent) {
      levels.add(current.entry);
    } else if(current is EntryUndent) {
      assert(current.entry == levels.last);
      final lastLevel = levels.removeLast();
      assert(current.entry == lastLevel);

      for(int i = 0; i < (indentCount * levels.length); i++) {
        sink.add(indentChar);
      }

      HtmlEntry.closeEntry(format, sink, lastLevel, nextType == EntryType.EOF);
    } else {

      for(int i = 0; i < (indentCount * levels.length); i++) {
        sink.add(indentChar);
      }

      HtmlEntry.writeEntry(format, sink, current, nextType, eval);
    }
  }

  Entry previous = null;

  return new Walker<Entry, String>(
      handleData: (Entry data, EventSink<String> sink) {
        _log(data);
        assert(data != null);
        if(previous == null) {
          previous = data;
        } else {
          lookAhead(sink, previous, EntryType.of(data));
          previous = data;
        }
      },
      handleDone: (EventSink<String> sink) {
        assert(levels.length <= 1);
        if(previous != null) {
          lookAhead(sink, previous, EntryType.of(null));
          previous = null;
        } else {
          assert(levels.isEmpty);
        }
        sink.close();
      });
}
