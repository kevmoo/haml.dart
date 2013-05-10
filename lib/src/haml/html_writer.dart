part of haml;

Walker<Entry, String> htmlEntryToHtml(
    {
      HamlFormat format: HamlFormat.HTML5,
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

  void lookAhead(EventSink<String> sink, Entry current, Entry next) {
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

      HtmlEntry.closeEntry(format, sink, lastLevel, next);
    } else {

      for(int i = 0; i < (indentCount * levels.length); i++) {
        sink.add(indentChar);
      }

      HtmlEntry.writeEntry(format, sink, current, next, eval);
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
          lookAhead(sink, previous, data);
          previous = data;
        }
      },
      handleDone: (EventSink<String> sink) {
        assert(levels.length <= 1);
        if(previous != null) {
          lookAhead(sink, previous, null);
          previous = null;
        } else {
          assert(levels.isEmpty);
        }
        sink.close();
      });
}
