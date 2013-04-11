part of core;

class Block {
  final EntryValue entry;
  final Sequence<Block> children;

  factory Block.raw(String header, [Iterable<Block> items = null]) {
    return new Block(new StringEntry(header), items);
  }

  Block(this.entry, [Iterable<Block> items = null]) :
    this.children = new ReadOnlyCollection(items == null ? [] : items) {
    requireArgumentNotNull(entry, 'entry');

    assert(children != null);
    assert(children.every((b) => b is Block));
  }

  String get header => entry.value;

  bool operator ==(other) => other is Block && entry == other.entry &&
        children.itemsEqual(other.children);

  int getTotalCount() => children.fold(1, (int val, Block child) =>
        val + child.getTotalCount());

  static String getPrefixedString(Iterable<Block> blocks) {
    final buffer = new StringBuffer();

    tokenToPrefixedLine().map(_getTokens(blocks))
      .forEach((l) => buffer.writeln(l));

    return buffer.toString();
  }

  static Iterable<dynamic> _getTokens(Iterable<Block> blocks) =>
    blocks.expand((b) => b.getTokens());

  Iterable<dynamic> getTokens() {
    if(children.isEmpty) {
      return [header];
    } else {
      return [[header, INDENT], _getTokens(children), [UNDENT]]
        .expand((e) => e);
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
