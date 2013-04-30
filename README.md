# Haml.dart

 * Main goal: a [haml-spec](https://github.com/haml/haml-spec) compliant implementation of [Haml](http://haml.info/) in Dart.
 * A bunch of helpers to parse indention-based grammars to make things like `Haml` (and hopefully `Sass`) easier.
 * Some thoughts — wrapped in the `Walker` class at the moment — on implementing the Dart `StreamTransformer` model in such a way to allow both asynchronous (`Stream`-, `Future`-based) and synchronous (`Iterable`-based) parsing of text.

Huge thanks to [Lukas Renggli](http://www.lukas-renggli.ch/) and his [PetitParserDart](https://github.com/renggli/PetitParserDart) library.

Currently passing 71 of 102 [haml-spec - modified](https://github.com/kevmoo/haml-spec) tests.

*Added some tests to haml-spec to keep myself honest in vague cases.*

```dart
import 'package:haml/haml.dart';

void main() {
  print('Sample 1:');
  var input = '%h1 Hello, Haml!';
  var output = hamlStringToHtml(input);
  print(output);

  print('Sample 2:');
  input  =
'''
#content
  .section.draft
    %p.paragraph.example Here's some content
    %img{ :src => 'http://foo.com/img.png', :alt => 'silly' }
  %a(href='http://foo.com') Link body
''';

  output = hamlStringToHtml(input);
  print(output);
}
```

Sample 1:

```html
<h1>Hello, Haml!</h1>
```

Sample 2:
```html
<div id='content'>
  <div class='draft section'>
    <p class='example paragraph'>Here's some content</p>
    <img alt='silly' src='http://foo.com/img.png'>
  </div>
  <a href='http://foo.com'>Link body</a>
</div>
```
