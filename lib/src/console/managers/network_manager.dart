import '../data/store/in_memory_store.dart';
import '../models/network_entry.dart';

/// Owns the captured [NetworkEntry] list and exposes filtered views for the
/// Network tab.
class NetworkManager {
  final InMemoryStore<NetworkEntry> _store;

  /// Creates a manager retaining up to [maxRequests] entries.
  NetworkManager({int maxRequests = 200})
    : _store = InMemoryStore<NetworkEntry>(maxItems: maxRequests);

  /// Snapshot of entries (newest first).
  List<NetworkEntry> get entries => _store.items;

  /// Stream of the full entry list on every change.
  Stream<List<NetworkEntry>> get stream => _store.stream;

  /// Records a new in-flight request.
  void addRequest(NetworkEntry entry) => _store.add(entry);

  /// Completes the request with id [id] with response/error data.
  void completeRequest(
    String id, {
    int? statusCode,
    Map<String, dynamic>? responseHeaders,
    dynamic responseBody,
    Duration? duration,
    int? responseSize,
    String? error,
    String? errorType,
  }) {
    _store.update((e) => e.id == id, (e) {
      e
        ..statusCode = statusCode
        ..responseHeaders = responseHeaders
        ..responseBody = responseBody
        ..duration = duration
        ..responseSize = responseSize
        ..error = error
        ..errorType = errorType
        ..isComplete = true;
      return e;
    });
  }

  /// Removes everything.
  void clear() => _store.clear();

  /// Closes the underlying stream.
  void dispose() => _store.dispose();
}
