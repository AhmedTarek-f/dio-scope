import 'failure.dart';

/// User-facing messages for each [FailureType].
///
/// dio_scope ships two complete built-in sets, [english] and [arabic], keyed
/// by language code in [builtIn]. Pass a live locale resolver to
/// `DioScope.init(locale: ...)` and every failure picks its copy from the
/// current language **at failure time**, so it follows an in-app language
/// switch with no static snapshot.
///
/// The app's own copy is optional: override a language (or add one) with
/// `DioScope.init(localizedMessages: {'ar': FailureMessages.arabic.copyWith(...)})`;
/// anything you don't override uses the built-in sets.
/// `DioScope.init(messages: ...)` sets the copy used when no locale resolves
/// (or its language has no entry); [english] by default. You can also pass
/// one directly to [safeApiCall].
///
/// To reword only a few strings, start from a built-in set with [copyWith]. A
/// brand-new language passes every message to the constructor.
class FailureMessages {
  /// Message for [FailureType.network] (no connectivity / transport error).
  final String network;

  /// Message for [FailureType.timeout] (connect / send / receive timeout).
  final String timeout;

  /// Message for [FailureType.server] (HTTP 5xx).
  final String server;

  /// Message for [FailureType.unauthorized] (HTTP 401).
  final String unauthorized;

  /// Message for [FailureType.forbidden] (HTTP 403).
  final String forbidden;

  /// Message for [FailureType.notFound] (HTTP 404).
  final String notFound;

  /// Message for [FailureType.badRequest] (HTTP 4xx client/validation errors).
  final String badRequest;

  /// Message for [FailureType.parsing] (response could not be deserialized).
  final String parsing;

  /// Message for [FailureType.cancellation] (request was cancelled).
  final String cancellation;

  /// Message for a failed TLS / certificate check.
  final String badCertificate;

  /// Message for [FailureType.unknown] (anything else).
  final String unknown;

  /// Creates a complete set of failure messages; every message is required.
  /// To change only a few, use `FailureMessages.english.copyWith(...)` (or
  /// [arabic]) instead.
  const FailureMessages({
    required this.network,
    required this.timeout,
    required this.server,
    required this.unauthorized,
    required this.forbidden,
    required this.notFound,
    required this.badRequest,
    required this.parsing,
    required this.cancellation,
    required this.badCertificate,
    required this.unknown,
  });

  /// The built-in English copy.
  static const FailureMessages english = FailureMessages(
    network:
        'No internet connection. Please check your network and try again.',
    timeout: 'The connection timed out. Please try again.',
    server: 'Something went wrong on our end. Please try again later.',
    unauthorized: 'Your session has expired. Please sign in again.',
    forbidden: "You don't have permission to perform this action.",
    notFound: 'The requested resource was not found.',
    badRequest: 'Please check your input and try again.',
    parsing: "We couldn't read the server response. Please try again.",
    cancellation: 'The request was cancelled.',
    badCertificate: 'A secure connection could not be established.',
    unknown: 'Something went wrong. Please try again.',
  );

  /// The built-in Arabic copy.
  static const FailureMessages arabic = FailureMessages(
    network:
        'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.',
    timeout: 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.',
    server: 'حدث خطأ من جهتنا. يرجى المحاولة مرة أخرى لاحقًا.',
    unauthorized: 'انتهت صلاحية جلستك. يرجى تسجيل الدخول مرة أخرى.',
    forbidden: 'ليس لديك صلاحية لتنفيذ هذا الإجراء.',
    notFound: 'المورد المطلوب غير موجود.',
    badRequest: 'يرجى التحقق من البيانات المدخلة والمحاولة مرة أخرى.',
    parsing: 'تعذّرت قراءة استجابة الخادم. يرجى المحاولة مرة أخرى.',
    cancellation: 'تم إلغاء الطلب.',
    badCertificate: 'تعذّر إنشاء اتصال آمن.',
    unknown: 'حدث خطأ ما. يرجى المحاولة مرة أخرى.',
  );

  /// Every built-in language, keyed by `Locale.languageCode`.
  static const Map<String, FailureMessages> builtIn = {
    'en': english,
    'ar': arabic,
  };

  /// Returns the message configured for [type].
  String forType(FailureType type) => switch (type) {
    FailureType.network => network,
    FailureType.timeout => timeout,
    FailureType.server => server,
    FailureType.unauthorized => unauthorized,
    FailureType.forbidden => forbidden,
    FailureType.notFound => notFound,
    FailureType.badRequest => badRequest,
    FailureType.parsing => parsing,
    FailureType.cancellation => cancellation,
    FailureType.unknown => unknown,
  };

  /// Returns a copy with the given fields replaced.
  FailureMessages copyWith({
    String? network,
    String? timeout,
    String? server,
    String? unauthorized,
    String? forbidden,
    String? notFound,
    String? badRequest,
    String? parsing,
    String? cancellation,
    String? badCertificate,
    String? unknown,
  }) {
    return FailureMessages(
      network: network ?? this.network,
      timeout: timeout ?? this.timeout,
      server: server ?? this.server,
      unauthorized: unauthorized ?? this.unauthorized,
      forbidden: forbidden ?? this.forbidden,
      notFound: notFound ?? this.notFound,
      badRequest: badRequest ?? this.badRequest,
      parsing: parsing ?? this.parsing,
      cancellation: cancellation ?? this.cancellation,
      badCertificate: badCertificate ?? this.badCertificate,
      unknown: unknown ?? this.unknown,
    );
  }
}
