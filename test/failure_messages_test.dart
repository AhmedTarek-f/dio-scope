import 'package:dio_scope/dio_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builtIn holds English and Arabic', () {
    expect(FailureMessages.builtIn.keys, unorderedEquals(['en', 'ar']));
    expect(FailureMessages.builtIn['en'], same(FailureMessages.english));
    expect(FailureMessages.builtIn['ar'], same(FailureMessages.arabic));
  });

  test('english is exactly the constructor defaults', () {
    const defaults = FailureMessages();
    for (final type in FailureType.values) {
      expect(FailureMessages.english.forType(type), defaults.forType(type));
    }
    expect(FailureMessages.english.badCertificate, defaults.badCertificate);
  });

  test('every Arabic message is filled in and translated', () {
    for (final type in FailureType.values) {
      final ar = FailureMessages.arabic.forType(type);
      expect(ar.trim(), isNotEmpty, reason: '$type');
      expect(ar, isNot(FailureMessages.english.forType(type)), reason: '$type');
    }
    expect(FailureMessages.arabic.badCertificate.trim(), isNotEmpty);
    expect(
      FailureMessages.arabic.badCertificate,
      isNot(FailureMessages.english.badCertificate),
    );
  });

  test('forType maps each type to its own field', () {
    const m = FailureMessages.arabic;
    expect(m.forType(FailureType.network), m.network);
    expect(m.forType(FailureType.timeout), m.timeout);
    expect(m.forType(FailureType.server), m.server);
    expect(m.forType(FailureType.unauthorized), m.unauthorized);
    expect(m.forType(FailureType.forbidden), m.forbidden);
    expect(m.forType(FailureType.notFound), m.notFound);
    expect(m.forType(FailureType.badRequest), m.badRequest);
    expect(m.forType(FailureType.parsing), m.parsing);
    expect(m.forType(FailureType.cancellation), m.cancellation);
    expect(m.forType(FailureType.unknown), m.unknown);
  });
}
