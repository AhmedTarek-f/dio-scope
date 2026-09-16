import 'package:dio_scope/dio_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(DioScope.dispose);

  test('disabled visibility keeps everything inert', () {
    DioScope.init(visibility: DioScopeVisibility.disabled);
    expect(DioScope.isEnabled, isFalse);
    expect(DioScope.networkManager, isNull);
    expect(DioScope.errorManager, isNull);
    // Still safe to call — no-ops.
    DioScope.log('ignored');
    expect(DioScope.interceptor(), isNotNull);
  });

  test('always visibility builds managers and stays configured', () {
    DioScope.init(visibility: DioScopeVisibility.always);
    expect(DioScope.isEnabled, isTrue);
    expect(DioScope.networkManager, isNotNull);
    expect(DioScope.errorManager, isNotNull);
    DioScope.log('hello');
    expect(DioScope.logManager!.entries.single.message, 'hello');
  });

  test('gate can veto an otherwise-enabled visibility', () {
    DioScope.init(visibility: DioScopeVisibility.always, gate: () => false);
    expect(DioScope.isEnabled, isFalse);
  });

  test('init configures the crash reporter even when disabled', () {
    DioScope.init(
      visibility: DioScopeVisibility.disabled,
      messages: const FailureMessages(unknown: 'custom'),
    );
    expect(DioScope.failureMessages.unknown, 'custom');
  });
}
