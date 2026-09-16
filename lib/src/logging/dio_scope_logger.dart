import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'log_level.dart';

/// A pluggable logging sink. dio_scope routes **every** captured error through
/// the registered logger (safeCall failures, uncaught framework/async errors,
/// and manual `DioScope.recordError`), plus your own `DioScope.log` calls.
///
/// The default is [DefaultDioScopeLogger] (writes via `dart:developer`). Swap in
/// your own — e.g. wrapping `package:logger` — via `DioScope.init(logger: ...)`.
abstract class DioScopeLogger {
  /// Const base constructor so implementations can be `const`.
  const DioScopeLogger();

  /// Writes a log line at [level], optionally with the originating [error],
  /// its [stackTrace], and a [tag]/category.
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  });

  /// Convenience for a debug-level line.
  void debug(String message, {String? tag}) =>
      log(LogLevel.debug, message, tag: tag);

  /// Convenience for an info-level line.
  void info(String message, {String? tag}) =>
      log(LogLevel.info, message, tag: tag);

  /// Convenience for a warning-level line.
  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) => log(
    LogLevel.warning,
    message,
    error: error,
    stackTrace: stackTrace,
    tag: tag,
  );

  /// Convenience for an error-level line.
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) => log(
    LogLevel.error,
    message,
    error: error,
    stackTrace: stackTrace,
    tag: tag,
  );
}

/// The default logger, writing via `dart:developer.log()` — so lines show up in
/// the IDE/DevTools with their severity, the error object, and the stack trace.
/// Zero extra dependencies.
class DefaultDioScopeLogger extends DioScopeLogger {
  /// Lines below this level are dropped. Defaults to [LogLevel.debug].
  final LogLevel minLevel;

  /// Whether logging is active. Defaults to `!kReleaseMode` — silent in release
  /// (errors still reach the `CrashReporter`). Pass `true` to log in release.
  final bool enabled;

  /// The default `developer.log` "name" used when a call has no `tag`.
  final String name;

  /// Creates the default logger.
  DefaultDioScopeLogger({
    this.minLevel = LogLevel.debug,
    bool? enabled,
    this.name = 'dio_scope',
  }) : enabled = enabled ?? !kReleaseMode;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (!enabled || level.index < minLevel.index) return;
    developer.log(
      message,
      level: _dartLevel(level),
      name: tag ?? name,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  // Maps to the conventional dart:developer / package:logging level values.
  int _dartLevel(LogLevel level) => switch (level) {
    LogLevel.debug => 500,
    LogLevel.info => 800,
    LogLevel.warning => 900,
    LogLevel.error => 1000,
  };
}

/// A logger that discards everything — use to fully opt out of logging.
class SilentDioScopeLogger extends DioScopeLogger {
  /// Creates a const no-op logger.
  const SilentDioScopeLogger();

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {}
}
