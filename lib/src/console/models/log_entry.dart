import '../../logging/log_level.dart';

export '../../logging/log_level.dart' show LogLevel;

/// A single app log line captured by `DioScope.log`.
class LogEntry {
  /// The log text.
  final String message;

  /// The severity.
  final LogLevel level;

  /// An optional tag/category.
  final String? tag;

  /// When the line was recorded.
  final DateTime timestamp;

  /// Creates a log entry (timestamp defaults to now).
  LogEntry({
    required this.message,
    this.level = LogLevel.info,
    this.tag,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// `HH:MM:SS.mmm` — matches the design's terminal-style rows.
  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}
