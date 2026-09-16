import 'dart:convert';

import 'package:dio/dio.dart';

import '../managers/network_manager.dart';
import '../models/network_entry.dart';

/// A Dio [Interceptor] that records every request/response/error into a
/// [NetworkManager] for the console Network tab.
///
/// Compared with a bare logger it also captures response headers, an estimated
/// payload size, and the `DioExceptionType` on failure, which the detail sheet
/// and timing waterfall rely on.
class CaptureInterceptor extends Interceptor {
  /// The manager receiving captured entries.
  final NetworkManager networkManager;

  /// Creates a capture interceptor.
  CaptureInterceptor(this.networkManager);

  static const _stopwatchKey = '_dio_scope_stopwatch';
  static const _entryIdKey = '_dio_scope_entry_id';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final stopwatch = Stopwatch()..start();
    final entryId = DateTime.now().microsecondsSinceEpoch.toString();
    options.extra[_stopwatchKey] = stopwatch;
    options.extra[_entryIdKey] = entryId;

    networkManager.addRequest(
      NetworkEntry(
        id: entryId,
        timestamp: DateTime.now(),
        method: options.method,
        url: options.uri.toString(),
        requestHeaders: Map<String, dynamic>.from(options.headers),
        queryParameters: options.queryParameters.isEmpty
            ? null
            : Map<String, dynamic>.from(options.queryParameters),
        requestBody: _describeBody(options.data),
      ),
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _complete(
      response.requestOptions,
      statusCode: response.statusCode,
      headers: response.headers,
      body: response.data,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _complete(
      err.requestOptions,
      statusCode: err.response?.statusCode,
      headers: err.response?.headers,
      body: err.response?.data,
      error: err.message ?? err.toString(),
      errorType: err.type.name,
    );
    handler.next(err);
  }

  void _complete(
    RequestOptions options, {
    int? statusCode,
    Headers? headers,
    dynamic body,
    String? error,
    String? errorType,
  }) {
    final stopwatch = options.extra[_stopwatchKey] as Stopwatch?;
    final entryId = options.extra[_entryIdKey] as String?;
    stopwatch?.stop();
    if (entryId == null) return;

    networkManager.completeRequest(
      entryId,
      statusCode: statusCode,
      responseHeaders: _flattenHeaders(headers),
      responseBody: _describeBody(body),
      duration: stopwatch?.elapsed,
      responseSize: _estimateSize(headers, body),
      error: error,
      errorType: errorType,
    );
  }

  Map<String, dynamic>? _flattenHeaders(Headers? headers) {
    if (headers == null) return null;
    final map = <String, dynamic>{};
    headers.forEach((name, values) => map[name] = values.join(', '));
    return map;
  }

  /// Converts non-JSON bodies (e.g. `FormData`) into an inspectable summary.
  dynamic _describeBody(dynamic data) {
    if (data == null) return null;
    if (data is FormData) {
      return {
        'fields': {for (final f in data.fields) f.key: f.value},
        'files': [
          for (final f in data.files) '${f.key}: ${f.value.filename ?? 'file'}',
        ],
      };
    }
    return data;
  }

  int? _estimateSize(Headers? headers, dynamic body) {
    final contentLength = headers?.value(Headers.contentLengthHeader);
    final parsed = contentLength == null ? null : int.tryParse(contentLength);
    if (parsed != null) return parsed;
    if (body == null) return null;
    try {
      if (body is String) return body.length;
      if (body is List<int>) return body.length;
      return jsonEncode(body).length;
    } catch (_) {
      return null;
    }
  }
}
