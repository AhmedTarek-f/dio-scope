import 'package:dio/dio.dart';

import 'failure_messages.dart';

/// A coarse classification of why a request failed. Map this to your own UI
/// (icons, illustrations, retry affordances) — dio_scope deliberately keeps
/// [Failure] free of any asset or widget coupling.
enum FailureType {
  /// No connectivity, DNS failure, TLS/certificate error, or unknown transport
  /// error — nothing came back from the server.
  network,

  /// A connect, send, or receive timeout elapsed.
  timeout,

  /// The server responded with 5xx.
  server,

  /// The server responded with 401.
  unauthorized,

  /// The server responded with 403.
  forbidden,

  /// The server responded with 404.
  notFound,

  /// The server responded with another 4xx (validation / client error).
  badRequest,

  /// The response body could not be deserialized (e.g. `FormatException`).
  parsing,

  /// The request was cancelled via a [CancelToken].
  cancellation,

  /// Anything not covered above.
  unknown,
}

/// An immutable, transport-agnostic description of a failed operation.
///
/// Built automatically by [Failure.fromDioException] inside `safeCall`, or
/// manually via [Failure.custom]. Carries a user-facing [message], the coarse
/// [type], the HTTP [statusCode] when known, optional field-level
/// [messageDetails], and the raw [details]/[stackTrace] for logging.
///
/// Equality is intentionally based only on `(type, statusCode, message)` so it
/// behaves well inside BLoC/Cubit state objects.
class Failure {
  /// The coarse category of this failure.
  final FailureType type;

  /// A user-facing, already-resolved message.
  final String message;

  /// Optional multi-line field/validation details (e.g. joined form errors).
  final String? messageDetails;

  /// The HTTP status code, when the failure came from a server response.
  final int? statusCode;

  /// The underlying error object (often the [DioException]); for logging only.
  final Object? details;

  /// The stack trace captured at the failure site, when available.
  final StackTrace? stackTrace;

  /// Creates a failure. Prefer the factories below in most code.
  const Failure({
    required this.type,
    required this.message,
    this.messageDetails,
    this.statusCode,
    this.details,
    this.stackTrace,
  });

  /// Returns a copy with the given fields replaced.
  Failure copyWith({
    FailureType? type,
    String? message,
    String? messageDetails,
    int? statusCode,
    Object? details,
    StackTrace? stackTrace,
  }) {
    return Failure(
      type: type ?? this.type,
      message: message ?? this.message,
      messageDetails: messageDetails ?? this.messageDetails,
      statusCode: statusCode ?? this.statusCode,
      details: details ?? this.details,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  /// Maps a [DioException] to a [Failure] using [messages] for default copy.
  ///
  /// When the server returns a body, its `message`/`error` field is preferred
  /// over the default text, and a list under `errors` is joined into
  /// [messageDetails]. To customize (e.g. domain-specific error codes), pass a
  /// `dioFailureMapper` to `DioScope.init` — `safeCall` calls it first and only
  /// falls back to this default when it returns `null`.
  factory Failure.fromDioException(
    DioException e, {
    FailureMessages messages = const FailureMessages(),
  }) {
    if (CancelToken.isCancel(e)) {
      return Failure(
        type: FailureType.cancellation,
        message: messages.cancellation,
        details: e,
        stackTrace: e.stackTrace,
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return Failure(
          type: FailureType.timeout,
          message: messages.timeout,
          details: e,
          stackTrace: e.stackTrace,
        );
      case DioExceptionType.badCertificate:
        return Failure(
          type: FailureType.network,
          message: messages.badCertificate,
          details: e,
          stackTrace: e.stackTrace,
        );
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final serverMessage = _extractMessage(e.response);
        final fieldErrors = _extractFieldErrors(e.response);
        final (resolvedType, fallback) = _classifyStatus(status, messages);
        return Failure(
          type: resolvedType,
          message: serverMessage ?? fallback,
          messageDetails: fieldErrors,
          statusCode: status,
          details: e,
          stackTrace: e.stackTrace,
        );
      case DioExceptionType.cancel:
        return Failure(
          type: FailureType.cancellation,
          message: messages.cancellation,
          details: e,
          stackTrace: e.stackTrace,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return Failure(
          type: FailureType.network,
          message: messages.network,
          details: e,
          stackTrace: e.stackTrace,
        );
    }
  }

  /// A failure with a caller-supplied [message] and [type] (default unknown).
  factory Failure.custom(
    String message, {
    FailureType type = FailureType.unknown,
    int? statusCode,
  }) {
    return Failure(type: type, message: message, statusCode: statusCode);
  }

  /// A response-parsing/deserialization failure.
  factory Failure.parsing(
    Object? details, {
    StackTrace? stackTrace,
    FailureMessages messages = const FailureMessages(),
  }) {
    return Failure(
      type: FailureType.parsing,
      message: messages.parsing,
      details: details,
      stackTrace: stackTrace,
    );
  }

  /// A catch-all failure for unexpected errors.
  factory Failure.unknown(
    Object? details, {
    StackTrace? stackTrace,
    FailureMessages messages = const FailureMessages(),
  }) {
    return Failure(
      type: FailureType.unknown,
      message: messages.unknown,
      details: details,
      stackTrace: stackTrace,
    );
  }

  static (FailureType, String) _classifyStatus(
    int? status,
    FailureMessages messages,
  ) {
    if (status == null) return (FailureType.unknown, messages.unknown);
    if (status >= 500) return (FailureType.server, messages.server);
    if (status == 401) return (FailureType.unauthorized, messages.unauthorized);
    if (status == 403) return (FailureType.forbidden, messages.forbidden);
    if (status == 404) return (FailureType.notFound, messages.notFound);
    if (status >= 400) return (FailureType.badRequest, messages.badRequest);
    return (FailureType.unknown, messages.unknown);
  }

  static String? _extractMessage(Response<dynamic>? response) {
    try {
      final data = response?.data;
      if (data == null) return null;
      if (data is String) return data.isEmpty ? null : data;
      if (data is Map) {
        final message = data['message'] ?? data['error'] ?? data['detail'];
        if (message != null) return message.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String? _extractFieldErrors(Response<dynamic>? response) {
    try {
      final data = response?.data;
      if (data is! Map) return null;
      final errors = data['errors'];
      if (errors is! List || errors.isEmpty) return null;
      final messages = errors
          .map(
            (e) => e is Map
                ? (e['message']?.toString() ?? e['msg']?.toString() ?? '')
                : e.toString(),
          )
          .where((m) => m.isNotEmpty)
          .toList();
      return messages.isEmpty ? null : messages.join('\n');
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() =>
      'Failure(type: $type, statusCode: $statusCode, message: $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          other.type == type &&
          other.statusCode == statusCode &&
          other.message == message;

  @override
  int get hashCode => Object.hash(type, statusCode, message);
}
