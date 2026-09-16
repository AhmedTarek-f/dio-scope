import 'package:flutter/widgets.dart';

import '../../config.dart';
import '../../models/error_entry.dart';
import '../../models/log_entry.dart';

/// The design's dark DevTools palette and typography, exposed as a data class
/// and provided to the subtree via [ConsoleThemeScope].
///
/// This is intentionally a self-contained, dark-only theme — the console does
/// not follow the host app's `ThemeData` (a developer tool wants a neutral,
/// predictable surface). Values come straight from the Claude Design handoff.
class ConsoleTheme {
  /// The accent color in effect (drives tabs, indicator, FAB gradient, links).
  final DioScopeAccent accentKind;

  /// Whether non-essential motion should be suppressed.
  final bool reduceMotion;

  /// Creates a theme for [accentKind].
  const ConsoleTheme({
    this.accentKind = DioScopeAccent.blue,
    this.reduceMotion = false,
  });

  static const String _fontPackage = 'dio_scope';

  // --- Backgrounds ---------------------------------------------------------
  /// Panel background.
  static const Color background = Color(0xFF0D1117);

  /// Host-app simulated background (used by the launcher demo).
  static const Color hostBackground = Color(0xFF0B0F16);

  /// Default surface (search field, small buttons).
  static const Color surface = Color(0xFF161B22);

  /// Elevated surface (toast, sheet close button).
  static const Color elevated = Color(0xFF1C2330);

  /// Card background.
  static const Color card = Color(0xFF141A24);

  /// Bottom-sheet / section-header background.
  static const Color sheet = Color(0xFF12161F);

  /// Code / terminal ground (JSON, stack traces, logs list).
  static const Color codeGround = Color(0xFF0A0D13);

  /// Empty-state icon tile background.
  static const Color emptyIconTile = Color(0xFF121821);

  // --- Lines ---------------------------------------------------------------
  /// Scrollbar thumb / strong divider.
  static const Color divider = Color(0xFF273244);

  /// Default border.
  static const Color border = Color(0xFF1E2734);

  /// Slightly stronger border (inputs, chips).
  static const Color borderStrong = Color(0xFF222C3A);

  /// Subtle border (row separators inside cards).
  static const Color borderSubtle = Color(0xFF1A2230);

  /// Faint border (code boxes).
  static const Color borderFaint = Color(0xFF161D29);

  /// Faintest border (log row separators).
  static const Color borderFaintest = Color(0xFF10151D);

  /// Hover border.
  static const Color borderHover = Color(0xFF33415A);

  // --- Text ----------------------------------------------------------------
  /// Primary text.
  static const Color textPrimary = Color(0xFFF8FAFC);

  /// Dimmed primary (headings on cards).
  static const Color textDim1 = Color(0xFFF1F5F9);

  /// Dimmed primary (values, endpoints).
  static const Color textDim2 = Color(0xFFE2E8F0);

  /// Dimmed primary (headers/body values).
  static const Color textDim3 = Color(0xFFCBD5E1);

  /// Secondary text.
  static const Color textSecondary = Color(0xFF94A3B8);

  /// Muted text.
  static const Color muted = Color(0xFF64748B);

  /// Dim muted.
  static const Color mutedDim = Color(0xFF475569);

  /// Dimmest muted (copy icons, empty icons).
  static const Color mutedDimmer = Color(0xFF3A4658);

  /// Grab handle / separator dots.
  static const Color handle = Color(0xFF334155);

  // --- Semantic ------------------------------------------------------------
  /// Blue.
  static const Color blue = Color(0xFF3B82F6);

  /// Violet.
  static const Color violet = Color(0xFF8B5CF6);

  /// Green.
  static const Color green = Color(0xFF22C55E);

  /// Cyan.
  static const Color cyan = Color(0xFF06B6D4);

  /// Amber.
  static const Color amber = Color(0xFFF59E0B);

  /// Red.
  static const Color red = Color(0xFFEF4444);

  /// Rose (critical).
  static const Color rose = Color(0xFFF43F5E);

  // --- JSON syntax ---------------------------------------------------------
  /// JSON key color.
  static const Color jsonKey = Color(0xFF7DD3FC);

  /// JSON string color.
  static const Color jsonString = Color(0xFF86EFAC);

  /// JSON number color.
  static const Color jsonNumber = Color(0xFFFBBF24);

  /// JSON boolean color.
  static const Color jsonBool = Color(0xFFC4B5FD);

  /// JSON null color.
  static const Color jsonNull = Color(0xFF94A3B8);

  /// JSON punctuation color.
  static const Color jsonPunct = Color(0xFF5B6B82);

  /// The resolved accent color.
  Color get accent => switch (accentKind) {
    DioScopeAccent.blue => blue,
    DioScopeAccent.violet => violet,
    DioScopeAccent.cyan => cyan,
  };

  /// Color for an HTTP [method] badge.
  Color methodColor(String method) => switch (method.toUpperCase()) {
    'GET' => green,
    'POST' => blue,
    'PUT' => amber,
    'PATCH' => violet,
    'DELETE' => red,
    _ => textSecondary,
  };

  /// Color for an HTTP status code (null = pending).
  Color statusColor(int? status) {
    if (status == null) return muted;
    if (status < 300) return green;
    if (status < 400) return cyan;
    if (status < 500) return amber;
    return red;
  }

  /// Color for a request [duration] (null = pending).
  Color durationColor(Duration? duration) {
    if (duration == null) return cyan;
    final ms = duration.inMilliseconds;
    if (ms < 300) return green;
    if (ms < 1200) return amber;
    return red;
  }

  /// Color for a log [level].
  Color logLevelColor(LogLevel level) => switch (level) {
    LogLevel.debug => blue,
    LogLevel.info => cyan,
    LogLevel.warning => amber,
    LogLevel.error => red,
  };

  /// Color for an error [severity].
  Color severityColor(ErrorSeverity severity) => switch (severity) {
    ErrorSeverity.widgetError => red,
    ErrorSeverity.asyncError => amber,
    ErrorSeverity.apiError => red,
    ErrorSeverity.exception => rose,
  };

  /// Color for a system group dot ([colorKey] = app/device/runtime/push).
  Color groupDotColor(String colorKey) => switch (colorKey) {
    'app' => blue,
    'device' => cyan,
    'runtime' => green,
    'push' => violet,
    _ => textSecondary,
  };

  /// A tinted pill/badge/chip decoration following the design's alpha rule:
  /// background at [bg] alpha, an optional border at [border] alpha.
  BoxDecoration tinted(
    Color color, {
    double bg = 0.14,
    double? border = 0.32,
    double radius = 99,
  }) => BoxDecoration(
    color: color.withValues(alpha: bg),
    borderRadius: BorderRadius.circular(radius),
    border: border == null
        ? null
        : Border.all(color: color.withValues(alpha: border)),
  );

  /// A UI (Cairo) text style.
  TextStyle ui({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color color = textPrimary,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontFamily: 'Cairo',
    package: _fontPackage,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  /// A monospace (JetBrains Mono) text style.
  TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w400,
    Color color = textPrimary,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontFamily: 'JetBrainsMono',
    package: _fontPackage,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  /// Reads the nearest [ConsoleTheme] from the widget tree.
  static ConsoleTheme of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ConsoleThemeScope>();
    assert(scope != null, 'No ConsoleThemeScope found in context');
    return scope!.theme;
  }
}

/// Provides a [ConsoleTheme] to descendants.
class ConsoleThemeScope extends InheritedWidget {
  /// The theme exposed to descendants.
  final ConsoleTheme theme;

  /// Creates a scope.
  const ConsoleThemeScope({
    super.key,
    required this.theme,
    required super.child,
  });

  @override
  bool updateShouldNotify(ConsoleThemeScope oldWidget) =>
      oldWidget.theme.accentKind != theme.accentKind ||
      oldWidget.theme.reduceMotion != theme.reduceMotion;
}
