part of core;

// just a place holder for everything else...
abstract class Entry { }

abstract class EntryDent implements Entry {
  final EntryValue entry;
  EntryDent._internal(this.entry) {
    assert(this.entry != null);
  }
}

class EntryIndent extends EntryDent {
  EntryIndent(EntryValue entry) : super._internal(entry);

  @override
  String toString() => 'Indent: $entry';
}

class EntryUndent extends EntryDent {
  EntryUndent(EntryValue entry) : super._internal(entry);

  @override
  String toString() => 'Undent: $entry';
}

abstract class EntryValue implements Entry {
  String get value;
}

class StringEntry implements EntryValue {
  final String value;

  StringEntry(this.value) {
    // TODO: I don't think this is baby sitting too much. Not sure we'll
    // ever support String entries starting with whitespace...for now...
    assert(!IndentLine.isWhite(value.codeUnits.first));

    // TODO: we might have a model for comments, which makes headers
    // multi-line. But for now...
    assert(!value.contains('\n'));
    assert(!value.contains('\r'));
  }

  @override
  bool operator ==(other) => other is StringEntry && other.value == value;

  @override
  String toString() => value;
}
