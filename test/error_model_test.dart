import 'package:dio_scope/dio_scope.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingReporter implements CrashReporter {
  final List<Map<String, Object?>?> information = [];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Map<String, Object?>? information,
  }) async {
    this.information.add(information);
  }

  @override
  Future<void> log(String message) async {}
  @override
  Future<void> setCustomKey(String key, Object value) async {}
  @override
  Future<void> setUserIdentifier(String identifier) async {}
}

DioException _dio(
  DioExceptionType type, {
  int? status,
  String method = 'GET',
  String path = '/x',
}) {
  final options = RequestOptions(path: path, method: method);
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<dynamic>(requestOptions: options, statusCode: status),
  );
}

void main() {
  group('Failure extension fields', () {
    test('fromDioException fills endpoint as "<METHOD> <path>"', () {
      final f = Failure.fromDioException(
        _dio(
          DioExceptionType.badResponse,
          status: 500,
          method: 'POST',
          path: '/orders',
        ),
      );
      expect(f.endpoint, 'POST /orders');
    });

    test('code/endpoint default to null and extra to const {}', () {
      const f = Failure(type: FailureType.unknown, message: 'x');
      expect(f.code, isNull);
      expect(f.endpoint, isNull);
      expect(f.extra, isEmpty);
    });

    test('copyWith carries code, endpoint and extra', () {
      const f = Failure(type: FailureType.badRequest, message: 'x');
      final g = f.copyWith(
        code: 'STORE_CLOSED',
        endpoint: 'GET /catalog',
        extra: {'animation': 'a.json'},
      );
      expect(g.code, 'STORE_CLOSED');
      expect(g.endpoint, 'GET /catalog');
      expect(g.extra['animation'], 'a.json');
      expect(g.type, FailureType.badRequest);
      expect(g.message, 'x');
    });

    test('equality distinguishes by code', () {
      const a = Failure(type: FailureType.badRequest, message: 'x', code: 'A');
      const b = Failure(type: FailureType.badRequest, message: 'x', code: 'B');
      const c = Failure(type: FailureType.badRequest, message: 'x', code: 'A');
      expect(a, isNot(b));
      expect(a, c);
      expect(a.hashCode, c.hashCode);
    });
  });

  group('isExpectedFailure override', () {
    late _RecordingReporter reporter;

    setUp(() => reporter = _RecordingReporter());
    tearDown(DioScope.dispose);

    test('a domain code marked expected is captured but NOT reported', () async {
      DioScope.init(
        visibility: DioScopeVisibility.always,
        crashReporter: reporter,
        dioFailureMapper: (e, messages) => Failure(
          type: FailureType.server,
          code: 'MAINTENANCE',
          message: 'down for maintenance',
          statusCode: e.response?.statusCode,
          details: e,
        ),
        isExpectedFailure: (f) =>
            kExpectedFailureTypes.contains(f.type) || f.code == 'MAINTENANCE',
      );

      final result = await safeApiCall<int>(
        () async => throw _dio(DioExceptionType.badResponse, status: 500),
      );
      await Future<void>.delayed(Duration.zero);

      expect(result.failureOrNull?.code, 'MAINTENANCE');
      // A `server` failure is normally reported; the custom predicate now
      // classifies this code as expected, so nothing reaches the reporter.
      expect(reporter.information, isEmpty);
      expect(DioScope.errorManager!.count, 1);
    });

    test('a reported bug forwards failureType + endpoint in information', () async {
      DioScope.init(
        visibility: DioScopeVisibility.always,
        crashReporter: reporter,
      );

      await safeApiCall<int>(
        () async => throw _dio(
          DioExceptionType.badResponse,
          status: 500,
          method: 'POST',
          path: '/pay',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(reporter.information.single, containsPair('failureType', 'server'));
      expect(reporter.information.single, containsPair('endpoint', 'POST /pay'));
    });
  });
}
