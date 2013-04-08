part of core;

class Block {
  final String header;
  final Sequence<Block> children;

  Block(this.header, [Iterable<Block> items = null]) :
    this.children = new ReadOnlyCollection(items == null ? [] : items) {
    requireArgumentNotNullOrEmpty(header, 'header');
    assert(!IndentLine.isWhite(header.codeUnits.first));

    // TODO: we might have a model for comments, which makes headers
    // multi-line. But for now...
    assert(!header.contains('\n'));
    assert(!header.contains('\r'));

    assert(children != null);
    assert(children.every((b) => b is Block));
  }

  bool operator ==(other) {
    return other is Block && other.header == this.header &&
        this.children.itemsEqual(other.children);
  }

  int getTotalCount() {
    return children.fold(1, (int val, Block child) {
      return val + child.getTotalCount();
    });
  }

  static String getPrefixedString(Iterable<Block> blocks) {
    final buffer = new StringBuffer();
    blocks.forEach((b) => b.writePrefixedString(buffer));
    return buffer.toString();
  }

  void writePrefixedString(StringSink buffer) {
    // if the header is entirely indent/undent chars, then double them
    String val;
    if(header.codeUnits.every((u) => u == _indentUnit)) {
      // TODO!!
      throw 'not impld';
    } else if(header.codeUnits.every((u) => u == _undentUnit)) {
      // TODO!!
      throw 'not impld';
    } else {
      val = header;
    }
    buffer.writeln(val);
    if(!children.isEmpty) {
      buffer.writeCharCode(_indentUnit);
      buffer.writeln();
      children.forEach((b) => b.writePrefixedString(buffer));
      buffer.writeCharCode(_undentUnit);
      buffer.writeln();
    }
  }

  static Iterable<Block> getBlocks(String source) {
    assert(source != null);

    return stringToBlocks().single(source);
  }

  static String getString(Iterable<Block> blocks, {int indentUnit,
    int indentCount: 2}) {
    final buffer = new StringBuffer();
    writeBlocks(buffer, blocks, indentUnit: indentUnit,
        indentCount: indentCount);
    return buffer.toString();
  }

  static void writeBlocks(StringSink buffer, Iterable<Block> blocks, {
    int level: 0, int indentUnit, int indentCount: 2}) {
    assert(level >= 0);
    if(indentUnit == null) {
      indentUnit = IndentLine._space;
    }
    assert(IndentLine.isWhite(indentUnit));
    assert(indentCount > 0);

    for(Block b in blocks) {
      for(var i = 0; i < level * indentCount; i++) {
        buffer.writeCharCode(indentUnit);
      }

      buffer.writeln(b.header);
      writeBlocks(buffer, b.children,
          level: level + 1, indentUnit: indentUnit, indentCount: indentCount);
    }
  }
}
