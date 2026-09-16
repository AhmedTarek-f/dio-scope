import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// How a [SystemInfoRow] value should be rendered.
enum SystemValueStyle {
  /// Normal text.
  plain,

  /// Monospace (for ids, numbers, tokens).
  mono,

  /// A green tag pill (positive/enabled).
  tagGood,

  /// An amber tag pill (attention, e.g. "development").
  tagWarn,

  /// A cyan tag pill (informational).
  tagInfo,
}

/// One label/value row inside a [SystemInfoGroup].
class SystemInfoRow {
  /// The row label.
  final String label;

  /// The row value.
  final String value;

  /// How the value should be styled.
  final SystemValueStyle style;

  /// Creates a row.
  const SystemInfoRow(
    this.label,
    this.value, {
    this.style = SystemValueStyle.plain,
  });
}

/// A titled group of [SystemInfoRow]s with a colored dot ([colorKey] is one of
/// `app`, `device`, `runtime`, `push`).
class SystemInfoGroup {
  /// The group heading.
  final String title;

  /// The dot color key.
  final String colorKey;

  /// The rows in this group.
  final List<SystemInfoRow> rows;

  /// Creates a group.
  const SystemInfoGroup(this.title, this.colorKey, this.rows);
}

/// Gathers app / device / runtime information for the console System tab.
class SystemInfoCollector {
  String? _environment;
  String? _fcmToken;

  /// Sets the environment/flavor label (e.g. "development").
  void setEnvironment(String environment) => _environment = environment;

  /// Sets the FCM token to display in the Push group.
  void setFcmToken(String token) => _fcmToken = token;

  /// The current FCM token, if any.
  String? get fcmToken => _fcmToken;

  /// Collects the grouped system information.
  Future<List<SystemInfoGroup>> collect() async {
    final groups = <SystemInfoGroup>[
      await _application(),
      await _device(),
      _runtime(),
    ];
    final push = _push();
    if (push != null) groups.add(push);
    return groups;
  }

  Future<SystemInfoGroup> _application() async {
    final rows = <SystemInfoRow>[];
    try {
      final info = await PackageInfo.fromPlatform();
      rows
        ..add(SystemInfoRow('App Name', info.appName))
        ..add(SystemInfoRow('Version', info.version, style: SystemValueStyle.mono))
        ..add(SystemInfoRow('Build Number', info.buildNumber, style: SystemValueStyle.mono))
        ..add(SystemInfoRow('Package', info.packageName, style: SystemValueStyle.mono));
    } catch (_) {
      rows.add(const SystemInfoRow('App Name', 'unavailable'));
    }
    if (_environment != null) {
      rows.add(SystemInfoRow('Environment', _environment!, style: SystemValueStyle.tagWarn));
    }
    rows.add(SystemInfoRow('Debug Mode', kDebugMode ? 'Enabled' : 'Disabled',
        style: kDebugMode ? SystemValueStyle.tagGood : SystemValueStyle.plain));
    return SystemInfoGroup('Application', 'app', rows);
  }

  Future<SystemInfoGroup> _device() async {
    final rows = <SystemInfoRow>[];
    final plugin = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final w = await plugin.webBrowserInfo;
        rows
          ..add(SystemInfoRow('Browser', w.browserName.name))
          ..add(SystemInfoRow('Platform', w.platform ?? 'Web'))
          ..add(SystemInfoRow('User Agent', w.userAgent ?? '-', style: SystemValueStyle.mono));
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            final a = await plugin.androidInfo;
            rows
              ..add(SystemInfoRow('Model', '${a.manufacturer} ${a.model}'))
              ..add(SystemInfoRow('Android', '${a.version.release} (SDK ${a.version.sdkInt})', style: SystemValueStyle.mono))
              ..add(SystemInfoRow('Device', a.device, style: SystemValueStyle.mono));
          case TargetPlatform.iOS:
            final i = await plugin.iosInfo;
            rows
              ..add(SystemInfoRow('Model', i.utsname.machine))
              ..add(SystemInfoRow('iOS', '${i.systemName} ${i.systemVersion}', style: SystemValueStyle.mono))
              ..add(SystemInfoRow('Name', i.name));
          case TargetPlatform.macOS:
            final m = await plugin.macOsInfo;
            rows
              ..add(SystemInfoRow('Model', m.model))
              ..add(SystemInfoRow('macOS', '${m.majorVersion}.${m.minorVersion}.${m.patchVersion}', style: SystemValueStyle.mono))
              ..add(SystemInfoRow('Host', m.computerName));
          case TargetPlatform.windows:
            final w = await plugin.windowsInfo;
            rows
              ..add(SystemInfoRow('Computer', w.computerName))
              ..add(SystemInfoRow('Windows', '${w.majorVersion}.${w.minorVersion} (build ${w.buildNumber})', style: SystemValueStyle.mono));
          case TargetPlatform.linux:
            final l = await plugin.linuxInfo;
            rows
              ..add(SystemInfoRow('Name', l.prettyName))
              ..add(SystemInfoRow('Version', l.version ?? '-', style: SystemValueStyle.mono));
          case TargetPlatform.fuchsia:
            rows.add(const SystemInfoRow('Platform', 'Fuchsia'));
        }
      }
    } catch (_) {
      rows.add(const SystemInfoRow('Device', 'unavailable'));
    }

    // Screen + locale from the platform dispatcher (no BuildContext needed).
    try {
      final view = PlatformDispatcher.instance.views.first;
      final size = view.physicalSize;
      final dpr = view.devicePixelRatio;
      rows.add(SystemInfoRow(
        'Screen',
        '${size.width.toStringAsFixed(0)}×${size.height.toStringAsFixed(0)} · ${dpr.toStringAsFixed(2)}x',
        style: SystemValueStyle.mono,
      ));
      rows.add(SystemInfoRow('Locale', PlatformDispatcher.instance.locale.toString(), style: SystemValueStyle.mono));
    } catch (_) {}

    return SystemInfoGroup('Device', 'device', rows);
  }

  SystemInfoGroup _runtime() {
    final mode = kReleaseMode
        ? 'release'
        : kProfileMode
        ? 'profile'
        : 'debug';
    final rows = <SystemInfoRow>[
      SystemInfoRow('Build Mode', mode, style: SystemValueStyle.tagInfo),
      SystemInfoRow('Web', kIsWeb ? 'Yes' : 'No'),
      SystemInfoRow('Target', defaultTargetPlatform.name, style: SystemValueStyle.mono),
    ];
    return SystemInfoGroup('Runtime', 'runtime', rows);
  }

  SystemInfoGroup? _push() {
    final token = _fcmToken;
    if (token == null || token.isEmpty) return null;
    return SystemInfoGroup('Push · FCM Token', 'push', [
      SystemInfoRow('Token', token, style: SystemValueStyle.mono),
    ]);
  }
}
