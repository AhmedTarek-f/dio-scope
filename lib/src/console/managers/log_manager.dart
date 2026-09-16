import '../data/store/in_memory_store.dart';
import '../models/log_entry.dart';

/// Owns the captured [LogEntry] list for the Logs tab.
class LogManager {
  final InMemoryStore<LogEntry> _store;

  /// Creates a manager retaining up to [maxLogs] entries.
  LogManager({int maxLogs = 500})
    : _store = InMemoryStore<LogEntry>(maxItems: maxLogs);

  /// Snapshot of entries (newest first).
  List<LogEntry> get entries => _store.items;

  /// Stream of the full entry list on every change.
  Stream<List<LogEntry>> get stream => _store.stream;

  /// Adds a log line.
  void log(String message, {LogLevel level = LogLevel.info, String? tag}) {
    _store.add(LogEntry(message: message, level: level, tag: tag));
  }

  /// Removes a single [entry] (used by swipe-to-dismiss).
  void removeEntry(LogEntry entry) => _store.remove((e) => identical(e, entry));

  /// Removes everything.
  void clear() => _store.clear();

  /// Closes the underlying stream.
  void dispose() => _store.dispose();
}
