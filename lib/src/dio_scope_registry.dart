import 'dart:ui' show Locale;

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

  /// The copy used when no locale resolves, or its language has no entry in
  /// [localizedMessages]. Set by `DioScope.init(messages: ...)`; defaults to
  /// English.
  static FailureMessages baseMessages = FailureMessages.english;

  /// Returns the app's current locale; called on every [messages] read so the
  /// copy follows an in-app language switch. `null` (the default) means
  /// [messages] is always [baseMessages].
  static Locale? Function()? localeResolver;

  /// Per-language copy keyed by `Locale.languageCode`. Defaults to the
  /// built-in [FailureMessages.builtIn] (English + Arabic).
  static Map<String, FailureMessages> localizedMessages =
      FailureMessages.builtIn;

  /// The active failure messages, resolved for the current locale **now**:
  /// the [localizedMessages] entry for [localeResolver]'s language, else
  /// [baseMessages]. A resolver that throws or returns `null` falls back to
  /// [baseMessages] too, so this never throws.
  static FailureMessages get messages {
    final resolver = localeResolver;
    if (resolver == null) return baseMessages;
    Locale? locale;
    try {
      locale = resolver();
    } catch (_) {
      return baseMessages;
    }
    if (locale == null) return baseMessages;
    return localizedMessages[locale.languageCode.toLowerCase()] ?? baseMessages;
  }

  /// The active logger. Every captured error is logged through this. Defaults
  /// to [DefaultDioScopeLogger] (writes via `dart:developer`).
  static DioScopeLogger logger = DefaultDioScopeLogger();

  /// Console sink for captured errors (set only when the console is enabled).
  static DioScopeErrorSink? errorSink;

  /// Optional domain-specific Dio → Failure mapper.
  static DioFailureMapper? dioFailureMapper;

  /// Classifies a [Failure] as an expected app state — surfaced to the user and
  /// console but **not** forwarded to the crash reporter. Defaults to
  /// [kExpectedFailureTypes] membership; override via
  /// `DioScope.init(isExpectedFailure: ...)` to also treat domain
  /// [Failure.code]s (e.g. a "store closed" state) as expected.
  static bool Function(Failure failure) isExpectedFailure = _defaultIsExpected;

  static bool _defaultIsExpected(Failure failure) =>
      kExpectedFailureTypes.contains(failure.type);

  /// Builds the console's capture interceptor. Set by `DioScope.init` (returns a
  /// no-op interceptor when the console is disabled); `null` before init, so
  /// `DioApiClient` simply skips auto-attaching it.
  static Interceptor Function()? consoleInterceptorFactory;

  /// Resets everything to defaults. Used by `DioScope.dispose` and tests.
  static void reset() {
    crashReporter = const NoopCrashReporter();
    baseMessages = FailureMessages.english;
    localeResolver = null;
    localizedMessages = FailureMessages.builtIn;
    logger = DefaultDioScopeLogger();
    errorSink = null;
    dioFailureMapper = null;
    isExpectedFailure = _defaultIsExpected;
    consoleInterceptorFactory = null;
  }
}
