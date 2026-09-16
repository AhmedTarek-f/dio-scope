import 'package:dio/dio.dart';

import '../dio_scope_registry.dart';
import 'api_client.dart';
import 'api_client_config.dart';
import 'api_response.dart';

/// The default [ApiClient], backed by Dio.
///
/// ```dart
/// final client = DioApiClient(const ApiClientConfig(baseUrl: 'https://api.example.com/'));
/// final res = await client.get('/users', queryParameters: {'page': 1});
/// ```
///
/// Failures are thrown as [DioException]s; wrap calls in `safeCall` at the
/// repository layer. If [ApiClientConfig.attachDebugConsole] is `true`, the
/// debug console's capture interceptor is attached automatically (a no-op when
/// the console is disabled).
class DioApiClient implements ApiClient {
  final Dio _dio;

  /// Creates a client from [config].
  DioApiClient(ApiClientConfig config)
    : _dio = config.dio ?? Dio(config.toBaseOptions()) {
    if (config.interceptors.isNotEmpty) {
      _dio.interceptors.addAll(config.interceptors);
    }
    if (config.attachDebugConsole) {
      final consoleInterceptor = DioScopeRegistry.consoleInterceptorFactory
          ?.call();
      if (consoleInterceptor != null) {
        _dio.interceptors.add(consoleInterceptor);
      }
    }
  }

  @override
  String get baseUrl => _dio.options.baseUrl;

  @override
  Dio get dio => _dio;

  @override
  void addInterceptor(Interceptor interceptor) =>
      _dio.interceptors.add(interceptor);

  @override
  void addInterceptors(List<Interceptor> interceptors) =>
      _dio.interceptors.addAll(interceptors);

  Options _mergeOptions(Options? options, Map<String, dynamic>? headers) {
    if (options == null) return Options(headers: headers);
    if (headers == null) return options;
    return options.copyWith(headers: {...?options.headers, ...headers});
  }

  ApiResponse _toApiResponse(Response<dynamic> response) {
    final flatHeaders = <String, dynamic>{};
    response.headers.forEach((name, values) {
      flatHeaders[name] = values.join(', ');
    });
    return ApiResponse(
      statusCode: response.statusCode ?? 0,
      data: response.data,
      headers: flatHeaders,
      requestPath: response.requestOptions.path,
    );
  }

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onReceiveProgress,
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: _mergeOptions(options, headers),
      onReceiveProgress: onReceiveProgress,
    );
    return _toApiResponse(response);
  }

  @override
  Future<ApiResponse> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final response = await _dio.post<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: _mergeOptions(options, headers),
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return _toApiResponse(response);
  }

  @override
  Future<ApiResponse> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final response = await _dio.put<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: _mergeOptions(options, headers),
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return _toApiResponse(response);
  }

  @override
  Future<ApiResponse> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final response = await _dio.patch<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: _mergeOptions(options, headers),
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return _toApiResponse(response);
  }

  @override
  Future<ApiResponse> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    final response = await _dio.delete<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: _mergeOptions(options, headers),
    );
    return _toApiResponse(response);
  }
}
