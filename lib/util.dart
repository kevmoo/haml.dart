library util;

import 'package:bot_io/bot_io.dart';

void log(value, [AnsiColor color = AnsiColor.RED]) {
  if(value is List) {
    value = value.join('\t');
  }
  print(new ShellString.withColor(value, color).format(true));
}

