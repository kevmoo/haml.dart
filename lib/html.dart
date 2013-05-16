library html;

import 'dart:async';
import 'package:meta/meta.dart';
import 'package:logging/logging.dart' as logging;
import 'package:petitparser/petitparser.dart';
import 'package:bot/bot.dart';
import 'package:petitparser/xml.dart' as xmlp;

import 'package:haml/core.dart';
import 'package:haml/dart_grammar.dart' as dart;

part 'src/html/html_writer.dart';
part 'src/html/html_format.dart';
part 'src/html/html_entry.dart';

logging.Logger _getLogger(String name) {
  return new logging.Logger(name);
}

class HtmlError implements Error {
  final String message;

  HtmlError(this.message) {
    requireArgumentNotNullOrEmpty(message, 'message');
  }

  @override
  String toString() => 'HtmlError: $message';
}
