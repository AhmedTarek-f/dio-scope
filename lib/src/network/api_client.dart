import 'package:dio/dio.dart';

import 'api_response.dart';

/// The HTTP contract your data sources depend on. Implemented by [DioApiClient]
/// but abstract so you can fake it in tests and keep Dio out of your data layer.
///
/// Methods throw a [DioException] on transport/HTTP errors — wrap calls in
/// `safeCall` at the repository layer to turn those into a `Result`.
abstract class ApiClient {
  /// The configured base URL.
  String get baseUrl;

  /// The underlying [Dio] instance — an escape hatch for advanced use
  /// (downloads, adapters, etc.). Prefer the verb methods for normal calls.
  Dio get dio;

  /// Adds a single [Interceptor] to the client.
  void addInterceptor(Interceptor interceptor);

  /// Adds several interceptors, in order.
  void addInterceptors(List<Interceptor> interceptors);

  /// Sends a GET request.
  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onReceiveProgress,
  });

  /// Sends a POST request with an optional [data] body.
  Future<ApiResponse> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Sends a PUT request with an optional [data] body.
  Future<ApiResponse> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Sends a PATCH request with an optional [data] body.
  Future<ApiResponse> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Sends a DELETE request with an optional [data] body.
  Future<ApiResponse> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Options? options,
  });
}
