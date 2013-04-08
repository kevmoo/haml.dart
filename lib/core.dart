library core;

import 'dart:async';
import 'package:bot/bot.dart';
import 'package:meta/meta.dart';
import 'package:petitparser/petitparser.dart';

import 'package:bot/bot_io.dart';
import 'util.dart';

part 'src/core/block.dart';
part 'src/core/grammar.dart';
part 'src/core/indent_line.dart';
part 'src/core/parser.dart';
part 'src/core/transformers.dart';
part 'src/core/walker.dart';

final _indentUnit = '+'.codeUnits.single;
final _undentUnit = '-'.codeUnits.single;
