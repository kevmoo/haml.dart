library harness_console;

import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';

main() {
  final config = new VMConfiguration();
  testCore(config);
}

void testCore(Configuration config) {
  configure(config);
  groupSep = ' - ';

  test('tbd', () {
    expect(true, isTrue);
  });
}
