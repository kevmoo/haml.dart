part of block;

class BlockParser extends BlockGrammar {

  void initialize() {
    super.initialize();

    action('block', (each) {
      assert(each != null);
      assert(each.length == 2);

      String header = each[0];
      List<Block> childBlocks = each[1] == null ? [] : each[1];

      var block = new Block(header, childBlocks);
      return block;
    });

  }
}
