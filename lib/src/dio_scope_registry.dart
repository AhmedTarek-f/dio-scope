import 'package:dio/dio.dart';

import 'crash/crash_reporter.dart';
import 'errors/failure.dart';
import 'errors/failure_messages.dart';
import 'logging/dio_scope_logger.dart';

/// Receives every error that flows through `safeCall` and the global error
/// guard, so the debug console can render it in the Errors tab. Wired by
/// `DioScope.init` when the console is enabled; `null` otherwise.
typedef DioScopeErrorSink =
    void Function(
      Object error,
      StackTrace? stack, {
      Failure? failure,
      String? source,
      String? kind,
    });

/// An optional hook to map a [DioException] to a domain-specific [Failure].
/// `safeCall` calls it first and falls back to [Failure.fromDioException] when
/// it returns `null`.
typedef DioFailureMapper =
    Failure? Function(DioException error, FailureMessages messages);

/// Process-wide configuration shared by the error/networking core and the
/// console, set by `DioScope.init`. Internal to the package.
///
/// This exists so `lib/src/errors` and `lib/src/crash` never need to import
/// `lib/src/console`, keeping the dependency graph one-directional.
class DioScopeRegistry {
  DioScopeRegistry._();

  /// The active crash reporter. Defaults to a no-op.
  static CrashReporter crashReporter = const NoopCrashReporter();

  /// The active failure messages. Defaults to English.
  static FailureMessages messages = const FailureMessages();

  /// The active logger. Every captured error is logged through this. Defaults
  /// to [DefaultDioScopeLogger] (writes via `dart:developer`).
  static DioScopeLogger logger = DefaultDioScopeLogger();

  /// Console sink for captured errors (set only when the console is enabled).
  static DioScopeErrorSink? errorSink;

  /// Optional domain-specific Dio → Failure mapper.
  static DioFailureMapper? dioFailureMapper;

  /// Builds the console's capture interceptor. Set by `DioScope.init` (returns a
  /// no-op interceptor when the console is disabled); `null` before init, so
  /// `DioApiClient` simply skips auto-attaching it.
  static Interceptor Function()? consoleInterceptorFactory;

  /// Resets everything to defaults. Used by `DioScope.dispose` and tests.
  static void reset() {
    crashReporter = const NoopCrashReporter();
    messages = const FailureMessages();
    logger = DefaultDioScopeLogger();
    errorSink = null;
    dioFailureMapper = null;
    consoleInterceptorFactory = null;
  }
}
