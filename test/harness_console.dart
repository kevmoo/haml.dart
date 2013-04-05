library harness_console;

import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'haml/haml_test.dart' as haml;
import 'block_parser_test.dart' as block;
import 'stream_test.dart' as stream;

main() {
  final config = new VMConfiguration();
  testCore(config);
}

void testCore(Configuration config) {
  unittestConfiguration = config;
  groupSep = ' - ';

  haml.main();
  block.main();
  group('stream', stream.main);
}
