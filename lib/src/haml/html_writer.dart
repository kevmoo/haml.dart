part of haml;

Walker<Entry, String> htmlEntryToHtml() {
  final _log = (val) => util.log(val, AnsiColor.GREEN);

  final indentChar = ' ';
  final indentCount = 2;

  final List<HtmlEntry> levels = new List<HtmlEntry>();

  HtmlEntry lastEntry;

  return new Walker<Entry, String>(
      handleData: (Entry data, EventSink<String> sink) {
        _log(data);
        if(data is EntryIndent) {
          assert(data.entry == lastEntry);
          levels.add(lastEntry);
          lastEntry = null;

        } else if(data is EntryUndent) {
          assert(data.entry == levels.last);
          final lastLevel = levels.removeLast();
          assert(data.entry == lastLevel);

          for(int i = 0; i < (indentCount * levels.length); i++) {
            sink.add(indentChar);
          }
          sink.add("</${lastLevel.value}>");

          lastEntry = null;

        } else {
          assert(data is HtmlEntry);

          if(lastEntry != null) {
            sink.add('\n');
          }


          lastEntry = data;

          for(int i = 0; i < (indentCount * levels.length); i++) {
            sink.add(indentChar);
          }

          sink.add("<${data.value}>");

        }
      },
      handleDone: (EventSink<String> sink) {
        assert(levels.isEmpty);
        if(lastEntry != null) {
          // does it need closing?
          _log('last thingy: $lastEntry');
        }
        sink.close();
      });
}

