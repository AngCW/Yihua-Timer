import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

/// Centralized application configuration.
/// All data paths are versioned so that different app versions
/// do not clash with each other's databases and assets.
///
/// Call [AppConfig.init] once at the very start of [main] before
/// using any path helpers.
class AppConfig {
  AppConfig._();

  /// The runtime version string, populated by [init] from package_info_plus.
  /// Falls back to the compile-time constant if init has not been called yet.
  static String _appVersion = '1.6.0'; // compile-time fallback

  /// The current application version string (major.minor.patch).
  static String get appVersion => _appVersion;

  /// Reads the real version from pubspec.yaml at runtime and stores it.
  /// Must be called once in [main] after [WidgetsFlutterBinding.ensureInitialized].
  static Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      // version is "1.6.0", buildNumber is "6" — we only want the semver part.
      _appVersion = info.version;
    } catch (_) {
      // Keep compile-time fallback if the platform channel fails.
    }
  }

  /// The versioned data folder name used inside the app support directory.
  /// - Release builds: `YiHuaTimer/v1.6.0`
  /// - Debug builds:   `YiHuaTimer/debug`
  ///
  /// This ensures:
  /// 1. Different release versions have isolated databases and assets.
  /// 2. Flutter debug/test runs never touch release data.
  static String get dataFolderName =>
      kDebugMode ? p.join('YiHuaTimer', 'debug') : p.join('YiHuaTimer', 'v$_appVersion');

  /// Returns the full versioned data path for the given support directory.
  /// Example: `C:\Users\...\AppData\Roaming\...\YiHuaTimer\v1.6.0`
  static String dataPath(String supportDirPath) =>
      p.join(supportDirPath, dataFolderName);
}
