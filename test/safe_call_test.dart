import 'package:dio_scope/dio_scope.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeReporter implements CrashReporter {
  final List<Object> errors = [];
  final List<bool> fatals = [];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Map<String, Object?>? information,
  }) async {
    errors.add(error);
    fatals.add(fatal);
  }

  @override
  Future<void> log(String message) async {}
  @override
  Future<void> setCustomKey(String key, Object value) async {}
  @override
  Future<void> setUserIdentifier(String identifier) async {}
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
  late _FakeReporter reporter;

  setUp(() {
    reporter = _FakeReporter();
    DioScope.init(
      visibility: DioScopeVisibility.always,
      crashReporter: reporter,
    );
  });

  tearDown(DioScope.dispose);

  test('success returns Ok and reports nothing', () async {
    final result = await safeApiCall(() async => 42);
    expect(result.dataOrNull, 42);
    expect(reporter.errors, isEmpty);
    expect(DioScope.errorManager!.count, 0);
  });

  test('server error is reported (non-fatal) and captured', () async {
    final result = await safeApiCall<int>(
      () async => throw _dio(DioExceptionType.badResponse, status: 500),
    );
    await Future<void>.delayed(Duration.zero);
    expect(result.failureOrNull?.type, FailureType.server);
    expect(reporter.errors.length, 1);
    expect(reporter.fatals.single, isFalse);
    expect(DioScope.errorManager!.count, 1);
  });

  test('expected failures are captured but NOT reported', () async {
    final result = await safeApiCall<int>(
      () async => throw _dio(DioExceptionType.connectionTimeout),
    );
    await Future<void>.delayed(Duration.zero);
    expect(result.failureOrNull?.type, FailureType.timeout);
    expect(reporter.errors, isEmpty);
    expect(DioScope.errorManager!.count, 1);
  });

  test('FormatException becomes a reported parsing failure', () async {
    final result = await safeApiCall<int>(
      () async => throw const FormatException('bad json'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(result.failureOrNull?.type, FailureType.parsing);
    expect(reporter.errors.length, 1);
  });
}
