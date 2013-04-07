library stream_test;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:bot/bot.dart';
import 'package:unittest/unittest.dart';

import 'package:okoboji/block.dart';

final _rnd = new math.Random();

Iterable<Iterable<int>> _getSquare(int size) {
  assert(size >= 0);
  return new Iterable.generate(size, (index) {
    return new Iterable.generate(size, (subIndex) {
      return index * size + subIndex;
    }).toList();
  }).toList();
}

void main() {
  test('crazy', () {
    final source = _getSquare(10);
    print(source);

    final output = _chunkList(15).map(source).toList();
    print('');
    print(output);

  });

  test('yay', () {

    final target = 30;

    final strStream = getRandomBlockStream(target);
    final byteStream = strStream.transform(new StringEncoder());
    final chunkStream = byteStream.transform(_chunkList(100));
    final decodedStream = chunkStream.transform(new StringDecoder());
    final lines = decodedStream.transform(splitLines());
    final magicLines = lines.transform(toLines());
    final flatLines = magicLines.transform(toFlat());
    final blockStream = flatLines.transform(toBlocks());

    return blockStream.toList()
        .then((list) {
          print('');
          print("results...");
          print('');
          print(Block.getString(list));

          var totalCount = list.fold(0, (int v, Block b) => v + b.getTotalCount());
          expect(totalCount, target);
        });
  });
}

typedef void _handleData<S, T>(S data, EventSink<T> sink);
typedef void _handleError<T>(AsyncError error, EventSink<T> sink);
typedef void _handleDone<T>(EventSink<T> sink);

class Walker<S, T> implements StreamTransformer<S, T> {
  final _handleData<S, T> _handleData;
  final _handleError<T> _handleError;
  final _handleDone<T> _handleDone;

  Walker({void handleData(S data, EventSink<T> sink),
    void handleError(AsyncError error, EventSink<T> sink),
    void handleDone(EventSink<T> sink)}) :
      _handleData = handleData, _handleError = handleError,
      _handleDone = handleDone;

  Iterable<T> map(Iterable<S> source) {
    assert(source != null);
    assert(_handleData != null);

    return new _WalkerIterable<S, T>(this, source);
  }

  Stream<T> bind(Stream<S> stream) {
    final tx = new StreamTransformer<S, T>(handleData: _handleData,
        handleError: _handleError, handleDone: _handleDone);
    return stream.transform(tx);
  }
}

class _WalkerIterable<S, T> extends Iterable<T> {
  final Iterable<S> _source;
  final Walker<S, T> _parent;

  _WalkerIterable(this._parent, this._source);

  Iterator<T> get iterator =>
      new _WalkerIterator<S, T>(_parent, _source.iterator);
}

class _WalkerIterator<S, T> implements Iterator<T> {
  final Walker<S, T> _parent;
  Iterator<S> _source;
  Iterator<T> _results;
  T _current;

  _WalkerIterator(this._parent, this._source);

  bool moveNext() {
    while(true) {
      if(_source == null) {
        _current = null;
        return false;
      }

      if(_results == null) {
        final sink = new _SillySink<T>();
        if(_source.moveNext()) {
          // lot's process results!
          _parent._handleData(_source.current, sink);
          _results = sink._items.iterator;
        } else {
          _source = null;
          _parent._handleDone(sink);
          _results = sink._items.iterator;
        }
      }

      if(_results.moveNext()) {
        _current = _results.current;
        return true;
      } else {
        _results = null;
      }
    }
  }

  T get current => _current;

}

class _SillySink<T> implements EventSink<T> {
  bool _done = false;
  final List<T> _items = new List<T>();

  void add(T data) {
    assert(!_done);
    _items.add(data);
  }

  void close() {
    assert(!_done);
    _done = true;
  }

  void addError(AsyncError e) {
    assert(!_done);
    throw e;
  }
}

Walker<List, List> _chunkList(int chunkSize) {
  assert(chunkSize > 0);
  List buffer;

  return new Walker<List, List>(
      handleData: (List data, EventSink<List> sink) {
        int index = 0;

        while(index < data.length) {
          if(buffer == null) {
            buffer = new List();
          }

          final startLength = buffer.length;
          assert(startLength < chunkSize);

          buffer.addAll(data.skip(index).take(chunkSize - startLength));
          index += buffer.length - startLength;

          if(buffer.length == chunkSize) {
            sink.add(buffer);
            buffer = null;
          } else {
            break;
          }
        }

      },
      handleDone: (EventSink<List> sink) {
        if(buffer != null && !buffer.isEmpty) {
          assert(buffer.length < chunkSize);
          sink.add(buffer);
        }
        sink.close();
      });
}

Stream<String> getRandomBlockStream(int rowCount) {
  assert(rowCount >= 0);

  final controller = new StreamController();

  var depth = null;

  Future.forEach(new Iterable.generate(rowCount, (e) => e), (i) {
    return Timer.run(() {
      depth = _getDepth(depth);
      String value = 'line $i at depth $depth';
      for(var i = 0; i < depth; i++) {
        value = '  ' + value;
      }
      value = value + '\n';
      controller.add(value);
    });
  }).then((_) {
    controller.close();
  });

  return controller.stream;
}

int _getDepth(int lastDepth) {
  if(lastDepth == null) {
    return 0;
  }
  var flip = lastDepth > 0 ? _rnd.nextInt(3) : _rnd.nextInt(2);

  switch(flip) {
    case 0:
      return lastDepth;
    case 1:
      return lastDepth + 1;
    case 2:
      assert(lastDepth > 0);
      return _rnd.nextInt(lastDepth);
    default:
      throw 'boo!';
  }
}
