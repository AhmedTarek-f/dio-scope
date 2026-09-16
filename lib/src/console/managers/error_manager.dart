import '../data/store/in_memory_store.dart';
import '../models/error_entry.dart';

/// Owns the captured [ErrorEntry] list for the Errors tab.
class ErrorManager {
  final InMemoryStore<ErrorEntry> _store;

  /// Creates a manager retaining up to [maxErrors] entries.
  ErrorManager({int maxErrors = 200})
    : _store = InMemoryStore<ErrorEntry>(maxItems: maxErrors);

  /// Snapshot of entries (newest first).
  List<ErrorEntry> get entries => _store.items;

  /// Stream of the full entry list on every change.
  Stream<List<ErrorEntry>> get stream => _store.stream;

  /// The number of captured errors (drives the FAB/tab badges).
  int get count => _store.items.length;

  /// Records a captured error.
  void record(ErrorEntry entry) => _store.add(entry);

  /// Removes everything.
  void clear() => _store.clear();

  /// Closes the underlying stream.
  void dispose() => _store.dispose();
}
