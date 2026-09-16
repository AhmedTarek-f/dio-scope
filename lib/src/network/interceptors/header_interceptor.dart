import 'dart:async';

import 'package:dio/dio.dart';

/// Computes a set of headers for a given request (may be async, e.g. reading
/// from secure storage).
typedef HeaderProvider =
    FutureOr<Map<String, dynamic>> Function(RequestOptions options);

/// Supplies the current auth token (or `null`/empty when signed out).
typedef TokenProvider = FutureOr<String?> Function();

/// A general-purpose header interceptor covering the common cases: constant
/// headers, per-request computed headers, and a bearer-style auth token —
/// without dio_scope needing to know about your storage or auth layer.
///
/// ```dart
/// client.addInterceptor(HeaderInterceptor(
///   staticHeaders: {'x-app-origin': 'MOBILE_APP'},
///   tokenProvider: () => secureStorage.readToken(),
/// ));
/// ```
class HeaderInterceptor extends Interceptor {
  /// Headers added to every request.
  final Map<String, dynamic> staticHeaders;

  /// Optional per-request headers (evaluated on each request).
  final HeaderProvider? dynamicHeaders;

  /// Optional auth-token source. When it returns a non-empty value, the token
  /// is placed under [authHeaderName] using [tokenBuilder].
  final TokenProvider? tokenProvider;

  /// The header name used for the auth token. Defaults to `Authorization`.
  final String authHeaderName;

  /// Formats the raw token into a header value. Defaults to `Bearer <token>`.
  final String Function(String token) tokenBuilder;

  /// Creates a header interceptor.
  HeaderInterceptor({
    this.staticHeaders = const {},
    this.dynamicHeaders,
    this.tokenProvider,
    this.authHeaderName = 'Authorization',
    String Function(String token)? tokenBuilder,
  }) : tokenBuilder = tokenBuilder ?? ((token) => 'Bearer $token');

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (staticHeaders.isNotEmpty) options.headers.addAll(staticHeaders);

    if (dynamicHeaders != null) {
      options.headers.addAll(await dynamicHeaders!(options));
    }

    if (tokenProvider != null) {
      final token = await tokenProvider!();
      if (token != null && token.isNotEmpty) {
        options.headers[authHeaderName] = tokenBuilder(token);
      }
    }

    handler.next(options);
  }
}
