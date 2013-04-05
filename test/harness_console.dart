library harness_console;

import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'haml/haml_test.dart' as haml;
import 'block_parser_test.dart' as block;

main() {
  final config = new VMConfiguration();
  testCore(config);
}

void testCore(Configuration config) {
  unittestConfiguration = config;
  groupSep = ' - ';

  haml.main();
  block.main();
}
