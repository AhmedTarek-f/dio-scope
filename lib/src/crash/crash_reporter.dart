/// A pluggable crash/error reporting sink.
///
/// dio_scope never depends on a concrete crash-reporting SDK (such as Firebase
/// Crashlytics or Sentry). Instead you implement [CrashReporter] and register
/// it once via `DioScope.init(crashReporter: ...)`, or pass it directly to
/// [safeApiCall]. `safeCall` forwards genuine bugs (server / parsing / unknown
/// failures) here as non-fatals; the global error guard forwards uncaught
/// framework and async errors here as fatals.
///
/// A ready-made Firebase Crashlytics adapter is provided in the README and the
/// example app — copy it into your app so the package stays Firebase-free.
abstract class CrashReporter {
  /// Const base constructor so implementations can be `const`.
  const CrashReporter();

  /// Records a non-fatal or fatal error with an optional [reason] and extra
  /// [information] (attached as custom keys by most backends).
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Map<String, Object?>? information,
  });

  /// Writes a breadcrumb-style log line to the reporter.
  Future<void> log(String message);

  /// Attaches a custom key/value that will be included with future reports.
  Future<void> setCustomKey(String key, Object value);

  /// Associates subsequent reports with a user identifier.
  Future<void> setUserIdentifier(String identifier);
}

/// The default [CrashReporter]: every method is a no-op.
///
/// Used whenever no reporter has been registered, which keeps dio_scope free of
/// any crash-reporting dependency until you opt in.
class NoopCrashReporter extends CrashReporter {
  /// Creates a const no-op reporter.
  const NoopCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Map<String, Object?>? information,
  }) async {}

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}

  @override
  Future<void> setUserIdentifier(String identifier) async {}
}
