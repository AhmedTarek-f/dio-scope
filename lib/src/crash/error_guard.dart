import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import '../dio_scope_registry.dart';
import '../logging/log_level.dart';
import 'crash_reporter.dart';

/// Installs dio_scope's global error handlers, implementing the standard Flutter
/// "error funnel". Uncaught errors are shown in the debug console's Errors tab
/// and forwarded to the [CrashReporter] (defaulting to the one registered via
/// `DioScope.init`) as **fatal**.
///
/// Call this in `main()` — ideally inside [runDioScopeGuarded], in the same zone
/// as `runApp` (see the zone-mismatch note below):
///
/// ```dart
/// void main() => runDioScopeGuarded(() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   DioScope.init(crashReporter: FirebaseCrashReporter());
///   installDioScopeErrorHandling();
///   runApp(const MyApp());
/// });
/// ```
///
/// Note: handlers set here do not exist inside a background isolate (e.g. an
/// FCM background handler marked `@pragma('vm:entry-point')`) — give such
/// isolates their own try/catch that calls `CrashReporter.recordError`.
void installDioScopeErrorHandling({
  CrashReporter? reporter,
  bool presentErrorsInDebug = true,
  Widget Function(FlutterErrorDetails details)? errorWidgetBuilder,
}) {
  final effective = reporter ?? DioScopeRegistry.crashReporter;

  FlutterError.onError = (FlutterErrorDetails details) {
    if (presentErrorsInDebug) FlutterError.presentError(details);
    DioScopeRegistry.logger.log(
      LogLevel.error,
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
      tag: 'FlutterError',
    );
    DioScopeRegistry.errorSink?.call(
      details.exception,
      details.stack,
      kind: 'widget',
      source: details.library,
    );
    unawaited(
      effective.recordError(
        details.exception,
        details.stack,
        reason: details.context?.toString(),
        fatal: true,
      ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    DioScopeRegistry.logger.log(
      LogLevel.error,
      error.toString(),
      error: error,
      stackTrace: stack,
      tag: 'PlatformDispatcher',
    );
    DioScopeRegistry.errorSink?.call(error, stack, kind: 'async');
    unawaited(effective.recordError(error, stack, fatal: true));
    return true;
  };

  if (errorWidgetBuilder != null) {
    ErrorWidget.builder = errorWidgetBuilder;
  }
}

/// Runs [body] inside a guarded zone, routing uncaught async errors to the
/// console Errors tab and the [CrashReporter] as fatal.
///
/// Zone-mismatch rule: call `WidgetsFlutterBinding.ensureInitialized()` and
/// `runApp()` **inside** [body] so the binding is created in this same zone.
R? runDioScopeGuarded<R>(R Function() body, {CrashReporter? reporter}) {
  return runZonedGuarded<R>(body, (error, stack) {
    final effective = reporter ?? DioScopeRegistry.crashReporter;
    DioScopeRegistry.logger.log(
      LogLevel.error,
      error.toString(),
      error: error,
      stackTrace: stack,
      tag: 'zone',
    );
    DioScopeRegistry.errorSink?.call(error, stack, kind: 'async');
    unawaited(effective.recordError(error, stack, fatal: true));
  });
}
