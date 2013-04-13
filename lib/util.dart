library util;

import 'package:bot_io/bot_io.dart';

void log(value, [AnsiColor color = AnsiColor.RED]) {
  if(value == null) {
    value = '*****null*****';
  } else {
    value = value.toString();
  }
  print(new ShellString.withColor(value, color).format(true));
}

