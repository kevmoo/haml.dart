library harness_console;

import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'haml/haml_test.dart' as haml;

main() {
  final config = new VMConfiguration();
  testCore(config);
}

void testCore(Configuration config) {
  configure(config);
  groupSep = ' - ';

  haml.main();

}
