/// A captured HTTP request/response pair, shown in the console Network tab.
///
/// Created on request and mutated in place when the response (or error)
/// arrives, so a single instance streams from pending → complete.
class NetworkEntry {
  /// A unique id used to correlate the request with its completion.
  final String id;

  /// When the request started.
  final DateTime timestamp;

  /// HTTP method (GET, POST, …).
  final String method;

  /// The full request URL.
  final String url;

  /// Request headers.
  final Map<String, dynamic>? requestHeaders;

  /// Query parameters, if any.
  final Map<String, dynamic>? queryParameters;

  /// Request body (any JSON-encodable value or `FormData` description).
  final dynamic requestBody;

  /// Response headers (set on completion).
  Map<String, dynamic>? responseHeaders;

  /// Response body (set on completion).
  dynamic responseBody;

  /// HTTP status code (set on completion; `null` while pending).
  int? statusCode;

  /// Round-trip duration (set on completion).
  Duration? duration;

  /// Error message, when the request failed.
  String? error;

  /// The `DioExceptionType` name, when the request failed.
  String? errorType;

  /// Approximate response size in bytes (from `content-length` or the encoded
  /// body length).
  int? responseSize;

  /// Whether the response/error has been recorded.
  bool isComplete;

  /// Creates a (pending) network entry.
  NetworkEntry({
    required this.id,
    required this.timestamp,
    required this.method,
    required this.url,
    this.requestHeaders,
    this.queryParameters,
    this.requestBody,
    this.responseHeaders,
    this.responseBody,
    this.statusCode,
    this.duration,
    this.error,
    this.errorType,
    this.responseSize,
    this.isComplete = false,
  });

  /// Whether the request is still in flight.
  bool get isPending => !isComplete;

  /// Whether the status code is 2xx.
  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;

  /// Whether the status code is 3xx.
  bool get isRedirect =>
      statusCode != null && statusCode! >= 300 && statusCode! < 400;

  /// Whether the status code is 4xx.
  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;

  /// Whether the status code is 5xx.
  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// Whether this request failed (error set or status >= 400).
  bool get isFailure => error != null || (statusCode != null && statusCode! >= 400);

  /// The parsed URL.
  Uri? get uri => Uri.tryParse(url);

  /// The path portion of the URL (with query), for compact display.
  String get path {
    final u = uri;
    if (u == null) return url;
    return u.hasQuery ? '${u.path}?${u.query}' : u.path;
  }

  /// The host portion of the URL.
  String get host => uri?.host ?? '';

  /// `HH:MM:SS` timestamp.
  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Human duration: `—` when pending, `1.23s` at/above 1s, else `123ms`.
  String get durationLabel {
    final d = duration;
    if (d == null) return '—';
    final ms = d.inMilliseconds;
    if (ms >= 1000) return '${(ms / 1000).toStringAsFixed(2)}s';
    return '${ms}ms';
  }

  /// Human size: `—` when unknown, else `B`/`KB`/`MB`.
  String get sizeLabel {
    final bytes = responseSize;
    if (bytes == null) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
