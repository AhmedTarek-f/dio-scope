import 'package:dio/dio.dart';

/// Configuration for a [DioApiClient], covering the common cases while leaving
/// a full [dio]/[baseOptions] override for anything bespoke.
class ApiClientConfig {
  /// The base URL every relative path is resolved against.
  final String baseUrl;

  /// Connection timeout. Defaults to 60s.
  final Duration connectTimeout;

  /// Receive timeout. Defaults to 60s.
  final Duration receiveTimeout;

  /// Send timeout. Defaults to 60s.
  final Duration sendTimeout;

  /// Headers sent with every request (merged with, and overridden by, per-call
  /// headers).
  final Map<String, dynamic> defaultHeaders;

  /// Interceptors added, in order, right after construction. A common ordering
  /// is: auth/header → app-context → (console capture, added automatically) →
  /// logging.
  final List<Interceptor> interceptors;

  /// Whether to automatically attach the debug console's capture interceptor
  /// (a no-op when the console is disabled). Defaults to `true`.
  final bool attachDebugConsole;

  /// A fully pre-built [Dio] to use instead of constructing one from the fields
  /// above — handy for tests or shared instances. When provided, [baseUrl] and
  /// the timeout/header fields are ignored (read from the Dio's own options).
  final Dio? dio;

  /// Extra [BaseOptions] overrides applied on top of the fields above (e.g.
  /// `responseType`, `validateStatus`, `contentType`).
  final BaseOptions? baseOptions;

  /// Creates a config. Only [baseUrl] is required (unless [dio] is supplied).
  const ApiClientConfig({
    this.baseUrl = '',
    this.connectTimeout = const Duration(seconds: 60),
    this.receiveTimeout = const Duration(seconds: 60),
    this.sendTimeout = const Duration(seconds: 60),
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    this.interceptors = const [],
    this.attachDebugConsole = true,
    this.dio,
    this.baseOptions,
  });

  /// Builds the [BaseOptions] represented by this config.
  BaseOptions toBaseOptions() {
    final base =
        baseOptions ??
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
          sendTimeout: sendTimeout,
          headers: Map<String, dynamic>.from(defaultHeaders),
        );
    // If a baseOptions override was supplied, still apply our top-level fields
    // when the override left them unset.
    if (baseOptions != null) {
      base
        ..baseUrl = base.baseUrl.isEmpty ? baseUrl : base.baseUrl
        ..connectTimeout ??= connectTimeout
        ..receiveTimeout ??= receiveTimeout
        ..sendTimeout ??= sendTimeout
        ..headers = {...defaultHeaders, ...base.headers};
    }
    return base;
  }
}
