part of html;

class HtmlError implements Error {
  final String message;

  HtmlError(this.message) {
    requireArgumentNotNullOrEmpty(message, 'message');
  }

  @override
  String toString() => 'HtmlError: $message';
}
