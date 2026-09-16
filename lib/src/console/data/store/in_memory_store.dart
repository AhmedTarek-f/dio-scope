import 'dart:async';

/// A simple newest-first, fixed-capacity in-memory store with a broadcast
/// stream. When capacity is exceeded the oldest items are evicted. Nothing is
/// persisted — everything is cleared on app restart.
class InMemoryStore<T> {
  /// The maximum number of retained items.
  final int maxItems;

  final List<T> _items = [];
  final StreamController<List<T>> _controller =
      StreamController<List<T>>.broadcast();

  /// Creates a store retaining up to [maxItems] items.
  InMemoryStore({this.maxItems = 500});

  /// An unmodifiable snapshot of the current items (newest first).
  List<T> get items => List.unmodifiable(_items);

  /// Broadcasts the full list on every change.
  Stream<List<T>> get stream => _controller.stream;

  /// Inserts [item] at the front, evicting the oldest beyond [maxItems].
  void add(T item) {
    _items.insert(0, item);
    if (_items.length > maxItems) {
      _items.removeRange(maxItems, _items.length);
    }
    _notify();
  }

  /// Replaces the first item matching [test] using [updater].
  void update(bool Function(T) test, T Function(T) updater) {
    final index = _items.indexWhere(test);
    if (index != -1) {
      _items[index] = updater(_items[index]);
      _notify();
    }
  }

  /// Removes all items matching [test].
  void remove(bool Function(T) test) {
    _items.removeWhere(test);
    _notify();
  }

  /// Removes everything.
  void clear() {
    _items.clear();
    _notify();
  }

  void _notify() {
    if (!_controller.isClosed) _controller.add(List.unmodifiable(_items));
  }

  /// Closes the broadcast stream.
  void dispose() {
    _controller.close();
  }
}
