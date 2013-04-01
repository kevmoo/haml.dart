part of haml;

class Block {
  final String header;
  final Sequence<Block> children;

  Block(this.header, Iterable<Block> items) :
    this.children = new ReadOnlyCollection(items) {
    assert(header != null);
    assert(!header.isEmpty);
    assert(children != null);
    assert(children.every((b) => b != null));
  }

  static Sequence<Block> getBlocks(String source) {
    assert(source != null);

    // whitespace: spaces + tabs
    // ignore whitespace-only lines

  }
}

/*
class _BlockIterable extends Iterable<Block> {
  final String source;

  _BlockIterable(this.source);

  Iterator<Block> get iterator => new _BlockIterator(source);
}

class _BlockIterator extends Iterator<Block> {
  final StringLineReader reader;

  _BlockIterator(String source) : this.reader = new StringLineReader(source) {
    assert(source != null);
  }

  bool moveNext() {
    if(reader.eof) {
      return false;
    }


  }


  Block get current => null;

}*/