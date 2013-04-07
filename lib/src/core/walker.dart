part of core;

// TODO: yeah, all of this should be in the BOT

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
