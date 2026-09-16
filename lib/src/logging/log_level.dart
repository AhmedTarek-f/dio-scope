/// Severity of a log line, shared by [DioScopeLogger] and the console Logs tab.
enum LogLevel {
  /// Verbose diagnostic detail.
  debug,

  /// Informational message.
  info,

  /// Something unexpected but recoverable.
  warning,

  /// An error condition.
  error,
}
