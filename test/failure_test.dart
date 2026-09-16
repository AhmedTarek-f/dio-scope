import 'package:dio_scope/dio_scope.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dio(
  DioExceptionType type, {
  int? status,
  dynamic body,
}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<dynamic>(
            requestOptions: options,
            statusCode: status,
            data: body,
          ),
  );
}

void main() {
  group('Failure.fromDioException', () {
    test('timeouts map to timeout', () {
      for (final t in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(Failure.fromDioException(_dio(t)).type, FailureType.timeout);
      }
    });

    test('connectionError / unknown map to network', () {
      expect(
        Failure.fromDioException(_dio(DioExceptionType.connectionError)).type,
        FailureType.network,
      );
      expect(
        Failure.fromDioException(_dio(DioExceptionType.unknown)).type,
        FailureType.network,
      );
    });

    test('status codes map correctly', () {
      final cases = <int, FailureType>{
        500: FailureType.server,
        503: FailureType.server,
        401: FailureType.unauthorized,
        403: FailureType.forbidden,
        404: FailureType.notFound,
        400: FailureType.badRequest,
        422: FailureType.badRequest,
      };
      cases.forEach((status, expected) {
        final f = Failure.fromDioException(
          _dio(DioExceptionType.badResponse, status: status),
        );
        expect(f.type, expected, reason: 'status $status');
        expect(f.statusCode, status);
      });
    });

    test('prefers server-provided message', () {
      final f = Failure.fromDioException(
        _dio(
          DioExceptionType.badResponse,
          status: 400,
          body: {'message': 'Email already taken'},
        ),
      );
      expect(f.message, 'Email already taken');
    });

    test('joins field errors into messageDetails', () {
      final f = Failure.fromDioException(
        _dio(
          DioExceptionType.badResponse,
          status: 422,
          body: {
            'errors': [
              {'message': 'Name required'},
              {'message': 'Email invalid'},
            ],
          },
        ),
      );
      expect(f.messageDetails, 'Name required\nEmail invalid');
    });

    test('uses custom messages when provided', () {
      const messages = FailureMessages(timeout: 'اتصال انتهت مهلته');
      final f = Failure.fromDioException(
        _dio(DioExceptionType.receiveTimeout),
        messages: messages,
      );
      expect(f.message, 'اتصال انتهت مهلته');
    });

    test('equality is by (type, statusCode, message)', () {
      const a = Failure(type: FailureType.server, message: 'x', statusCode: 500);
      const b = Failure(type: FailureType.server, message: 'x', statusCode: 500);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
