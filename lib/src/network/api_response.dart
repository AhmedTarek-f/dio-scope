/// A transport-agnostic wrapper around an HTTP response.
///
/// [ApiClient] returns this instead of a Dio `Response` so your data sources
/// never import Dio directly and can be tested without it.
class ApiResponse {
  /// The HTTP status code.
  final int statusCode;

  /// The decoded response body (`Map`, `List`, `String`, …).
  final dynamic data;

  /// The response headers, flattened to single comma-joined string values.
  final Map<String, dynamic> headers;

  /// The request path/URL this response came from, when known.
  final String? requestPath;

  /// Creates an [ApiResponse].
  const ApiResponse({
    required this.statusCode,
    this.data,
    this.headers = const {},
    this.requestPath,
  });

  /// Whether [statusCode] is in the 2xx range.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  @override
  String toString() =>
      'ApiResponse(statusCode: $statusCode, path: $requestPath)';
}
