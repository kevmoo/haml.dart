# Okoboji (working name, a lake I grew up close to)

 * Main goal: a [haml-spec](https://github.com/haml/haml-spec) compliant implementation of [Haml](http://haml.info/) in Dart.
 * A bunch of helpers to parse indention-based grammars to make things like `Haml` (and hopefully `Sass`) easier.
 * Some thoughts — wrapped in the `Walker` class at the moment — on implementing the Dart `StreamTransformer` model in such a way to allow both asynchronous (`Stream`-, `Future`-based) and synchronous (`Iterable`-based) parsing of text.

Huge thanks to [Lukas Renggli](http://www.lukas-renggli.ch/) and his [PetitParserDart](https://github.com/renggli/PetitParserDart) library.

Currently passing 68 of 100 [haml-spec - modified](https://github.com/kevmoo/haml-spec) tests.

*Added some tests to haml-spec to keep myself honest in vague cases.*
