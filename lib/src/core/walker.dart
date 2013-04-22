part of core;

// TODO: yeah, all of this should be in the BOT

typedef void _handleData<S, T>(S data, EventSink<T> sink);
typedef void _handleError<T>(error, EventSink<T> sink);
typedef void _handleDone<T>(EventSink<T> sink);

// TODO: ponder Walker.fromExpand ... with an onDone method
// call-backs that return Iterable<T> ... is nice?
// one could argue this would replace fromMap. Folks could just return [item]
abstract class Walker<S, T> implements StreamTransformer<S, T> {

  factory Walker({void handleData(S data, EventSink<T> sink),
    void handleDone(EventSink<T> sink)}) {
    return new _WalkerImpl(handleData, handleDone);
  }

  factory Walker.fromMap(T mapper(S)) {
    return new _WalkerFromMap(mapper);
  }

  Walker._internal();

  // TODO: map should really be expand...ish?
  // Not really map. Not really expand. Hmm...
  Iterable<T> map(Iterable<S> source);

  Iterable<T> single(S source) => map([source]);

  Walker<S, dynamic> chain(Walker<T, dynamic> value) =>
      new _ChainedWalker<S, dynamic>(this, value);
}

class _WalkerFromMap<S, T> extends Walker<S, T> {
  final Func1<S, T> _mapper;

  _WalkerFromMap(this._mapper) : super._internal();

  @override
  Iterable<T> map(Iterable<S> source) => source.map(_mapper);

  @override
  Stream<T> bind(Stream<S> stream) => stream.map(_mapper);
}

class _WalkerImpl<S, T> extends Walker<S, T> {
  final _handleData<S, T> _handleData;
  final _handleDone<T> _handleDone;

  _WalkerImpl(this._handleData, this._handleDone) :
    super._internal();

  @override
  Iterable<T> map(Iterable<S> source) {
    assert(source != null);
    assert(_handleData != null);

    return new _WalkerIterable<S, T>(this, source);
  }

  @override
  Stream<T> bind(Stream<S> stream) {
    final tx = new StreamTransformer<S, T>(handleData: _handleData,
        handleDone: _handleDone);
    return stream.transform(tx);
  }

  void handleData(data, EventSink sink) {
    if(_handleData == null) {
      sink.add(data);
    } else {
      _handleData(data, sink);
    }
  }

  void handleDone(EventSink<T> sink) {
    if(_handleDone == null) {
      sink.close();
    } else {
      _handleDone(sink);
    }
  }
}

class _ChainedWalker<S, T> extends Walker<S, T> {
  final ReadOnlyCollection<Walker> _walkers;

  _ChainedWalker(Walker<S, dynamic> first, Walker<dynamic, T> second) :
    _walkers = _expand(first, second), super._internal();

  @override
  Iterable<T> map(Iterable<S> source) {
    Iterable chainedIterable = source;
    _walkers.forEach((w) {
      chainedIterable = w.map(chainedIterable);
    });
    return chainedIterable;
  }

  @override
  Stream<T> bind(Stream<S> stream) {
    Stream chainedStream = stream;
    _walkers.forEach((w) {
      chainedStream = chainedStream.transform(w);
    });
    return chainedStream;
  }

  static ReadOnlyCollection<Walker> _expand(Walker first, Walker second) {
    return new ReadOnlyCollection<Walker>([first, second].expand((w) {
      if(w is _ChainedWalker) {
        return w._walkers;
      } else {
        return [w];
      }
    }));
  }
}

class _WalkerIterable<S, T> extends IterableBase<T> {
  final Iterable<S> _source;
  final _WalkerImpl<S, T> _parent;

  _WalkerIterable(this._parent, this._source);

  @override
  Iterator<T> get iterator =>
      new _WalkerIterator<S, T>(_parent, _source.iterator);
}

class _WalkerIterator<S, T> implements Iterator<T> {
  final _WalkerImpl<S, T> _parent;
  Iterator<S> _source;
  Iterator<T> _results;
  T _current;

  _WalkerIterator(this._parent, this._source);

  @override
  bool moveNext() {
    while(_results != null || _source != null) {
      if(_results == null) {
        final sink = new _SillySink<T>();
        if(_source.moveNext()) {
          // lot's process results!
          _parent.handleData(_source.current, sink);
          _results = sink._items.iterator;
        } else {
          _source = null;
          _parent.handleDone(sink);
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
    _current = null;
    return false;
  }

  @override
  T get current => _current;
}

class _SillySink<T> implements EventSink<T> {
  bool _done = false;
  final List<T> _items = new List<T>();

  @override
  void add(T data) {
    assert(!_done);
    _items.add(data);
  }

  @override
  void close() {
    assert(!_done);
    _done = true;
  }

  @override
  void addError(error) {
    assert(!_done);
    throw error;
  }
}
