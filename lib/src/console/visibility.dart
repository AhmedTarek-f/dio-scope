import 'package:flutter/foundation.dart';

/// Controls when the debug console (launcher + capture) is active.
///
/// This directly answers "show in debug / development / release, or turn it
/// off" — the environment control dio_scope is designed around.
enum DioScopeVisibility {
  /// Enabled only in debug builds (`kDebugMode`). The safe default.
  debug,

  /// Enabled in debug and profile builds, but not release (`!kReleaseMode`).
  nonRelease,

  /// Enabled in every build mode, including release. Use with care.
  always,

  /// Never enabled — the console is fully inert and the capture interceptor is
  /// a no-op.
  disabled,
}

/// Resolves whether the console should be enabled for [visibility].
///
/// If [gate] is provided it is AND-ed with the mode check, so you can combine a
/// base mode with a runtime switch (a build flavor, a remote flag, a hidden
/// unlock). For example `visibility: always, gate: () => prefs.debugUnlocked`
/// keeps the console off until the user unlocks it, in any build mode.
bool resolveDioScopeVisibility(
  DioScopeVisibility visibility,
  bool Function()? gate,
) {
  final base = switch (visibility) {
    DioScopeVisibility.debug => kDebugMode,
    DioScopeVisibility.nonRelease => !kReleaseMode,
    DioScopeVisibility.always => true,
    DioScopeVisibility.disabled => false,
  };
  if (!base) return false;
  return gate?.call() ?? true;
}
