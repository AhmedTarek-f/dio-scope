import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../dio_scope_registry.dart';
import '../crash/crash_reporter.dart';
import '../errors/failure.dart';
import '../errors/failure_messages.dart';
import '../logging/dio_scope_logger.dart';
import 'config.dart';
import 'data/capture_interceptor.dart';
import 'data/system_info_collector.dart';
import 'managers/error_manager.dart';
import 'managers/log_manager.dart';
import 'managers/network_manager.dart';
import 'models/error_entry.dart';
import 'models/log_entry.dart';
import 'ui/console_screen.dart';
import 'visibility.dart';

/// The entry point for the dio_scope debug console and shared configuration.
///
/// Call [init] once in `main()`, add [interceptor] to your Dio client (or let
/// [DioApiClient] attach it automatically), drop an `DioScopeOverlay` into your
/// `MaterialApp.builder`, and use [log]/[recordError] anywhere.
///
/// Everything is gated by [DioScopeVisibility]: in a disabled/release build the
/// console is inert and [interceptor] is a no-op, yet [init] still configures
/// the `safeCall` crash reporter and messages, so your data layer behaves
/// identically in every build mode.
class DioScope {
  DioScope._();

  static NetworkManager? _network;
  static LogManager? _logs;
  static ErrorManager? _errors;
  static SystemInfoCollector? _system;
  static CaptureInterceptor? _capture;

  static DebugConsoleOptions _options = const DebugConsoleOptions();
  static DioScopeVisibility _visibility = DioScopeVisibility.debug;
  static bool Function()? _gate;
  static bool _initialized = false;
  static int _seq = 0;

  /// Whether the console is currently enabled (visibility + gate resolved).
  static bool get isEnabled => resolveDioScopeVisibility(_visibility, _gate);

  /// The active crash reporter (also used by `safeCall`).
  static CrashReporter get crashReporter => DioScopeRegistry.crashReporter;

  /// The active failure messages (also used by `safeCall`).
  static FailureMessages get failureMessages => DioScopeRegistry.messages;

  /// The console options in effect.
  static DebugConsoleOptions get options => _options;

  /// The network manager, or `null` when disabled.
  static NetworkManager? get networkManager =>
      isEnabled && _initialized ? _network : null;

  /// The log manager, or `null` when disabled.
  static LogManager? get logManager => isEnabled && _initialized ? _logs : null;

  /// The error manager, or `null` when disabled.
  static ErrorManager? get errorManager =>
      isEnabled && _initialized ? _errors : null;

  /// The system-info collector, or `null` when disabled.
  static SystemInfoCollector? get systemInfoCollector =>
      isEnabled && _initialized ? _system : null;

  /// Initializes dio_scope. Safe to call once; a second call is ignored unless
  /// [dispose] was called first.
  ///
  /// - [visibility]/[gate] control when the console is active.
  /// - [crashReporter]/[messages]/[dioFailureMapper]/[isExpectedFailure]
  ///   configure `safeCall` in every build mode (even when the console is
  ///   disabled).
  /// - [environment] labels the System tab (e.g. "development").
  static void init({
    DioScopeVisibility visibility = DioScopeVisibility.debug,
    bool Function()? gate,
    CrashReporter? crashReporter,
    FailureMessages? messages,
    DioFailureMapper? dioFailureMapper,
    bool Function(Failure failure)? isExpectedFailure,
    DioScopeLogger? logger,
    DebugConsoleOptions console = const DebugConsoleOptions(),
    String? environment,
  }) {
    if (_initialized) return;
    _visibility = visibility;
    _gate = gate;
    _options = console;

    // Always configure the shared core so `safeCall` and the logger behave
    // identically regardless of whether the console UI is enabled.
    DioScopeRegistry.crashReporter = crashReporter ?? const NoopCrashReporter();
    DioScopeRegistry.messages = messages ?? const FailureMessages();
    DioScopeRegistry.logger = logger ?? DefaultDioScopeLogger();
    DioScopeRegistry.dioFailureMapper = dioFailureMapper;
    if (isExpectedFailure != null) {
      DioScopeRegistry.isExpectedFailure = isExpectedFailure;
    }

    if (!isEnabled) {
      DioScopeRegistry.consoleInterceptorFactory = null;
      DioScopeRegistry.errorSink = null;
      _initialized = true;
      return;
    }

    _network = NetworkManager(maxRequests: console.maxRequests);
    _logs = LogManager(maxLogs: console.maxLogs);
    _errors = ErrorManager(maxErrors: console.maxErrors);
    _system = SystemInfoCollector();
    if (environment != null) _system!.setEnvironment(environment);
    _capture = CaptureInterceptor(_network!);

    DioScopeRegistry.consoleInterceptorFactory = () => _capture ?? Interceptor();
    DioScopeRegistry.errorSink = _sink;

    _initialized = true;
  }

  /// Returns the console's Dio capture interceptor (a no-op when disabled).
  static Interceptor interceptor() =>
      isEnabled && _capture != null ? _capture! : Interceptor();

  /// Records an app log line — always to the dev output (via the registered
  /// logger) and, when the console is enabled, into the Logs tab.
  static void log(String message, {LogLevel level = LogLevel.info, String? tag}) {
    DioScopeRegistry.logger.log(level, message, tag: tag);
    if (!isEnabled) return;
    _logs?.log(message, level: level, tag: tag);
  }

  /// Records an error into the Errors tab and forwards it to the crash reporter
  /// as a non-fatal. Use for manual, handled errors you still want visibility
  /// on. (Uncaught errors are handled by the global error guard instead.)
  static void recordError(
    Object error,
    StackTrace? stack, {
    ErrorSeverity severity = ErrorSeverity.exception,
    String? title,
    String? subtitle,
    String? source,
  }) {
    // Log to the dev output even when the console is disabled.
    DioScopeRegistry.logger.log(
      LogLevel.error,
      title ?? _firstLine(error.toString()),
      error: error,
      stackTrace: stack,
      tag: source ?? 'recordError',
    );
    if (isEnabled) {
      _errors?.record(
        ErrorEntry(
          id: _nextId(),
          severity: severity,
          title: title ?? _firstLine(error.toString()),
          subtitle: subtitle,
          source: source,
          stackTrace: stack?.toString(),
        ),
      );
    }
    unawaited(crashReporter.recordError(error, stack, fatal: false));
  }

  /// Sets the FCM token shown in the System tab.
  static void setFcmToken(String token) {
    if (!isEnabled) return;
    _system?.setFcmToken(token);
  }

  /// Builds the console widget, or `null` when disabled/uninitialized. Used by
  /// [showConsole] and by `DioScopeOverlay`. Pass [onClose] to override the
  /// back button (the overlay uses this to dismiss its layer).
  static Widget? buildConsole({VoidCallback? onClose}) {
    if (!isEnabled || !_initialized) return null;
    return ConsoleScreen(
      networkManager: _network!,
      logManager: _logs!,
      errorManager: _errors!,
      systemInfoCollector: _system!,
      options: _options,
      onClose: onClose,
    );
  }

  /// Opens the full-screen debug console as a route on the nearest navigator.
  static void showConsole(BuildContext context) {
    final console = buildConsole();
    if (console == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => console),
    );
  }

  /// Tears everything down and resets shared configuration. Mainly for tests.
  static void dispose() {
    _network?.dispose();
    _logs?.dispose();
    _errors?.dispose();
    _network = null;
    _logs = null;
    _errors = null;
    _system = null;
    _capture = null;
    _initialized = false;
    _visibility = DioScopeVisibility.debug;
    _gate = null;
    _options = const DebugConsoleOptions();
    DioScopeRegistry.reset();
  }

  // The internal sink used by `safeCall` and the global error guard to push
  // errors into the Errors tab (crash forwarding is done by the caller).
  static void _sink(
    Object error,
    StackTrace? stack, {
    Failure? failure,
    String? source,
    String? kind,
  }) {
    if (!isEnabled) return;
    final title = failure?.message ?? _firstLine(error.toString());
    _errors?.record(
      ErrorEntry(
        id: _nextId(),
        severity: _severityFor(failure, kind),
        title: title,
        subtitle: source ?? _subtitleFor(failure),
        source: _sourceFor(failure),
        stackTrace: (stack ?? failure?.stackTrace)?.toString(),
      ),
    );
    // Also mirror into the Logs tab so it is a complete stream (incl. errors).
    if (_options.logErrorsToConsoleLog) {
      _logs?.log(title, level: LogLevel.error, tag: source ?? kind ?? 'error');
    }
  }

  static ErrorSeverity _severityFor(Failure? failure, String? kind) {
    if (kind != null) {
      return switch (kind) {
        'widget' => ErrorSeverity.widgetError,
        'async' => ErrorSeverity.asyncError,
        'api' => ErrorSeverity.apiError,
        'exception' => ErrorSeverity.exception,
        _ => ErrorSeverity.exception,
      };
    }
    return failure != null ? ErrorSeverity.apiError : ErrorSeverity.exception;
  }

  static String? _subtitleFor(Failure? failure) {
    if (failure == null) return null;
    final status = failure.statusCode;
    final base = status != null
        ? 'HTTP $status · ${failure.type.name}'
        : failure.type.name;
    return failure.code != null ? '$base · ${failure.code}' : base;
  }

  static String? _sourceFor(Failure? failure) {
    if (failure == null) return null;
    final endpoint = failure.endpoint;
    if (endpoint != null && endpoint.isNotEmpty) return endpoint;
    final details = failure.details;
    if (details is DioException) {
      final o = details.requestOptions;
      return '${o.method} ${o.path}'.trim();
    }
    return null;
  }

  static String _firstLine(String text) {
    final line = text.split('\n').first.trim();
    return line.length > 140 ? '${line.substring(0, 140)}…' : line;
  }

  static String _nextId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_seq++}';
}
