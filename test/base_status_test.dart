import 'package:dio_scope/dio_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BaseStatus', () {
    test('init has no data and reports flags', () {
      final s = BaseStatus<int>.init();
      expect(s.isInit, isTrue);
      expect(s.isLoading, isFalse);
      expect(s.dataOrNull, isNull);
      expect(s.error, isNull);
    });

    test('loading can retain previous data', () {
      final s = BaseStatus<int>.loading(data: 5);
      expect(s.isLoading, isTrue);
      expect(s.dataOrNull, 5);
    });

    test('success carries data', () {
      final s = BaseStatus<int>.success(9);
      expect(s.isSuccess, isTrue);
      expect(s.data, 9);
      expect(s.dataOrNull, 9);
    });

    test('error carries failure', () {
      final f = Failure.custom('boom');
      final s = BaseStatus<int>.error(f);
      expect(s.isError, isTrue);
      expect(s.error, f);
      expect(s.dataOrNull, isNull);
    });

    test('when folds all states', () {
      String describe(BaseStatus<int> s) => s.when(
        onInit: (_) => 'init',
        onLoading: (_) => 'loading',
        onSuccess: (d) => 'success:$d',
        onError: (f) => 'error:${f.message}',
      );
      expect(describe(BaseStatus<int>.init()), 'init');
      expect(describe(BaseStatus<int>.loading()), 'loading');
      expect(describe(BaseStatus<int>.success(3)), 'success:3');
      expect(describe(BaseStatus<int>.error(Failure.custom('e'))), 'error:e');
    });
  });
}
