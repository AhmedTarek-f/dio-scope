/// The accent color of the console (mirrors the design's `accent` prop).
enum DioScopeAccent {
  /// `#3B82F6` (default).
  blue,

  /// `#8B5CF6`.
  violet,

  /// `#06B6D4`.
  cyan,
}

/// Tunable options for the debug console.
class DebugConsoleOptions {
  /// Max retained network requests. Defaults to 200.
  final int maxRequests;

  /// Max retained log lines. Defaults to 500.
  final int maxLogs;

  /// Max retained errors. Defaults to 200.
  final int maxErrors;

  /// The accent color. Defaults to [DioScopeAccent.blue].
  final DioScopeAccent accent;

  /// Whether to reduce/disable non-essential motion. Defaults to `false`
  /// (the running app's `MediaQuery.disableAnimations` is also honored).
  final bool reduceMotion;

  /// Whether the FAB shows the cyan "network activity" ring while requests are
  /// in flight. Defaults to `true`.
  final bool liveActivity;

  /// Whether captured errors are also mirrored into the Logs tab (at error
  /// level), in addition to the Errors tab and the dev output. Defaults to
  /// `true`.
  final bool logErrorsToConsoleLog;

  /// Whether to show the draggable floating launcher button. Defaults to
  /// `true`. When `false`, open the console yourself via `DioScope.showConsole`.
  final bool showLauncher;

  /// Creates a set of console options.
  const DebugConsoleOptions({
    this.maxRequests = 200,
    this.maxLogs = 500,
    this.maxErrors = 200,
    this.accent = DioScopeAccent.blue,
    this.reduceMotion = false,
    this.liveActivity = true,
    this.logErrorsToConsoleLog = true,
    this.showLauncher = true,
  });
}
