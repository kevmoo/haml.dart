library harness_console;

import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'haml/haml_test.dart' as haml;
import 'core/block_parser_test.dart' as block;
import 'core/stream_test.dart' as stream;

main() {
  final config = new VMConfiguration();
  testCore(config);
}

void testCore(Configuration config) {
  unittestConfiguration = config;
  groupSep = ' - ';

  group('haml', haml.main);

  group('core', () {
    group('block', block.main);
    group('stream', stream.main);
  });
}
