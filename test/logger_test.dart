import 'package:dio/dio.dart';
import 'package:dio_scope/dio_scope.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingLogger extends DioScopeLogger {
  final List<({LogLevel level, String message, Object? error, String? tag})>
  calls = [];

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    calls.add((level: level, message: message, error: error, tag: tag));
  }
}

DioException _dio(DioExceptionType type, {int? status}) {
  final options = RequestOptions(path: '/x', method: 'GET');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<dynamic>(requestOptions: options, statusCode: status),
  );
}

void main() {
  late _CapturingLogger logger;

  setUp(() {
    logger = _CapturingLogger();
    DioScope.init(visibility: DioScopeVisibility.always, logger: logger);
  });

  tearDown(DioScope.dispose);

  test('safeCall logs every failure — expected AND bug', () async {
    await safeApiCall<int>(
      () async => throw _dio(DioExceptionType.badResponse, status: 401),
    );
    await safeApiCall<int>(
      () async => throw _dio(DioExceptionType.badResponse, status: 500),
    );
    final safeCallLogs =
        logger.calls.where((c) => c.tag == 'safeCall').toList();
    expect(safeCallLogs.length, 2);
    expect(safeCallLogs.every((c) => c.level == LogLevel.error), isTrue);
    expect(safeCallLogs.every((c) => c.error is DioException), isTrue);
  });

  test('recordError logs at error level', () {
    DioScope.recordError(StateError('boom'), StackTrace.current);
    final rec = logger.calls.where((c) => c.tag == 'recordError').single;
    expect(rec.level, LogLevel.error);
    expect(rec.error, isA<StateError>());
  });

  test('DioScope.log routes through the logger', () {
    DioScope.log('hello', level: LogLevel.warning, tag: 'demo');
    final line = logger.calls.where((c) => c.tag == 'demo').single;
    expect(line.level, LogLevel.warning);
    expect(line.message, 'hello');
  });

  test('captured errors are mirrored into the Logs tab', () async {
    await safeApiCall<int>(
      () async => throw _dio(DioExceptionType.badResponse, status: 500),
    );
    final logs = DioScope.logManager!.entries;
    expect(logs.any((e) => e.level == LogLevel.error), isTrue);
  });

  test('SilentDioScopeLogger swallows everything', () {
    DioScope.dispose();
    DioScope.init(
      visibility: DioScopeVisibility.always,
      logger: const SilentDioScopeLogger(),
    );
    // Should not throw and should not surface anywhere via the logger.
    expect(
      () => DioScope.log('ignored', level: LogLevel.error),
      returnsNormally,
    );
  });
}
