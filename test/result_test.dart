import 'package:dio_scope/dio_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('ok exposes data via when/fold/dataOrNull', () {
      const Result<int> r = Result.ok(42);
      expect(r.isOk, isTrue);
      expect(r.isError, isFalse);
      expect(r.dataOrNull, 42);
      expect(r.failureOrNull, isNull);
      expect(r.when(onOk: (d) => d * 2, onError: (_) => -1), 84);
      expect(r.fold((_) => -1, (d) => d + 1), 43);
      expect(r.getOrElse(0), 42);
    });

    test('error exposes failure', () {
      final f = Failure.custom('nope');
      final Result<int> r = Result.error(f);
      expect(r.isError, isTrue);
      expect(r.dataOrNull, isNull);
      expect(r.failureOrNull, f);
      expect(r.getOrElse(7), 7);
      expect(r.when(onOk: (_) => 'ok', onError: (fail) => fail.message), 'nope');
    });

    test('map transforms ok and passes failure through', () {
      const Result<int> ok = Result.ok(2);
      expect(ok.map((v) => 'v$v').dataOrNull, 'v2');

      final Result<int> err = Result.error(Failure.custom('x'));
      final mapped = err.map((v) => 'v$v');
      expect(mapped.isError, isTrue);
      expect(mapped.failureOrNull?.message, 'x');
    });

    test('equality by value', () {
      expect(const OkResult(1), const OkResult(1));
      expect(
        FailureResult<int>(Failure.custom('a')),
        FailureResult<int>(Failure.custom('a')),
      );
    });
  });
}
