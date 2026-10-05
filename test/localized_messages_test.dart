import 'package:dio_scope/dio_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dio(DioExceptionType type) =>
    DioException(requestOptions: RequestOptions(path: '/x'), type: type);

/// A repo using only the mixin — no localization glue of its own.
class _Repo with SafeApiCall {
  Future<Result<String>> badCast() => safeCall(() async {
    final dynamic value = 'not a map';
    return (value as Map<String, dynamic>)['key'] as String;
  });

  Future<Result<String>> boom() => safeCall(() async => throw Exception('x'));
}

void main() {
  tearDown(DioScope.dispose);

  void init({
    Locale? Function()? locale,
    FailureMessages? messages,
    Map<String, FailureMessages>? localizedMessages,
    Failure? Function(DioException, FailureMessages)? dioFailureMapper,
  }) => DioScope.init(
    visibility: DioScopeVisibility.disabled,
    locale: locale,
    messages: messages,
    localizedMessages: localizedMessages,
    dioFailureMapper: dioFailureMapper,
  );

  test('without a locale resolver everything stays English', () async {
    init();
    final result = await safeApiCall<int>(
      () async => throw _dio(DioExceptionType.connectionTimeout),
    );
    expect(result.failureOrNull?.message, FailureMessages.english.timeout);
  });

  test('an Arabic locale yields the built-in Arabic copy', () async {
    init(locale: () => const Locale('ar'));
    final result = await safeApiCall<int>(
      () async => throw _dio(DioExceptionType.connectionTimeout),
    );
    expect(result.failureOrNull?.message, FailureMessages.arabic.timeout);
  });

  test('the language code match ignores region and case', () {
    init(locale: () => const Locale('AR', 'EG'));
    expect(DioScope.failureMessages.network, FailureMessages.arabic.network);
  });

  test('a SafeApiCall repo gets Arabic parsing / unknown copy', () async {
    init(locale: () => const Locale('ar'));
    final repo = _Repo();

    final parsing = (await repo.badCast()).failureOrNull!;
    expect(parsing.type, FailureType.parsing);
    expect(parsing.message, FailureMessages.arabic.parsing);

    final unknown = (await repo.boom()).failureOrNull!;
    expect(unknown.type, FailureType.unknown);
    expect(unknown.message, FailureMessages.arabic.unknown);
  });

  test('the copy follows the live locale (no boot-time snapshot)', () async {
    var current = const Locale('en');
    init(locale: () => current);
    final repo = _Repo();

    final en = (await repo.boom()).failureOrNull!.message;
    current = const Locale('ar');
    final ar = (await repo.boom()).failureOrNull!.message;

    expect(en, FailureMessages.english.unknown);
    expect(ar, FailureMessages.arabic.unknown);
  });

  group('falls back to `messages`', () {
    const base = FailureMessages(unknown: 'base');

    test('when the resolver returns null', () {
      init(locale: () => null, messages: base);
      expect(DioScope.failureMessages.unknown, 'base');
    });

    test('when the language has no entry', () {
      init(locale: () => const Locale('fr'), messages: base);
      expect(DioScope.failureMessages.unknown, 'base');
    });

    test('when the resolver throws', () {
      init(locale: () => throw StateError('no context'), messages: base);
      expect(DioScope.failureMessages.unknown, 'base');
    });
  });

  test('localizedMessages overrides a built-in language and adds new ones', () {
    var current = const Locale('ar');
    init(
      locale: () => current,
      localizedMessages: {
        'ar': FailureMessages.arabic.copyWith(network: 'مخصص'),
        'fr': const FailureMessages(network: 'Pas de connexion'),
      },
    );
    expect(DioScope.failureMessages.network, 'مخصص');
    expect(DioScope.failureMessages.timeout, FailureMessages.arabic.timeout);

    current = const Locale('fr');
    expect(DioScope.failureMessages.network, 'Pas de connexion');

    // English is still the built-in copy.
    current = const Locale('en');
    expect(DioScope.failureMessages.network, FailureMessages.english.network);
  });

  test('dioFailureMapper receives the locale-resolved messages', () async {
    FailureMessages? received;
    init(
      locale: () => const Locale('ar'),
      dioFailureMapper: (e, messages) {
        received = messages;
        return null;
      },
    );

    final result = await safeApiCall<int>(
      () async => throw _dio(DioExceptionType.connectionError),
    );

    expect(received?.network, FailureMessages.arabic.network);
    // Falling back to the built-in mapping uses the same copy.
    expect(result.failureOrNull?.message, FailureMessages.arabic.network);
  });

  test('Failure factories default to the registered copy', () {
    init(locale: () => const Locale('ar'));

    expect(
      Failure.unknown(Exception()).message,
      FailureMessages.arabic.unknown,
    );
    expect(Failure.parsing(null).message, FailureMessages.arabic.parsing);
    expect(
      Failure.fromDioException(_dio(DioExceptionType.receiveTimeout)).message,
      FailureMessages.arabic.timeout,
    );
    // An explicit `messages` still wins.
    expect(
      Failure.unknown(null, messages: FailureMessages.english).message,
      FailureMessages.english.unknown,
    );
  });
}
