import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart';

class ShareAppService {
  /// Packages the application into a ZIP file and saves it to the Downloads directory.
  /// If [withData] is true, it exports current SharedPreferences and Drift database
  /// into a special folder `__yihua_import_data__` inside the zip, which the app
  /// automatically import on its next launch.
  static Future<void> shareApp({required bool withData, required String outZipPath}) async {
    try {
      // 1. Get the current application directory
      final String executablePath = Platform.resolvedExecutable;
      if (!Platform.isWindows) {
        throw Exception("此功能仅支持 Windows (This feature only supports Windows).");
      }
      final Directory appDir = File(executablePath).parent;

      // 2. Create a temporary staging directory
      final tempBase = await getTemporaryDirectory();
      final String tempDirName = "YiHuaTimer_Export_${DateTime.now().millisecondsSinceEpoch}";
      final Directory stagingDir = Directory(p.join(tempBase.path, tempDirName));
      if (await stagingDir.exists()) {
        await stagingDir.delete(recursive: true);
      }
      await stagingDir.create(recursive: true);

      final Directory appCopyDir = Directory(p.join(stagingDir.path, "YiHuaTimer"));
      await appCopyDir.create(recursive: true);

      // 3. Copy app files to staging directory
      // On Windows, the application consists of the exe, data folder, and dlls.
      print('Staging application files from ${appDir.path}...');
      await _recursiveCopy(appDir, appCopyDir);

      // 4. Export SharedPreferences (always) and data (if withData is true)
      final Directory importDataDir = Directory(p.join(appCopyDir.path, '__yihua_import_data__'));
      await importDataDir.create(recursive: true);

      // a. Export SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final Map<String, dynamic> prefsData = {};
      
      if (withData) {
        for (String key in keys) {
          prefsData[key] = prefs.get(key);
        }
      } else {
        // Export only shortcut keys if not sharing all data
        if (prefs.containsKey('hotkey_settings')) {
          prefsData['hotkey_settings'] = prefs.get('hotkey_settings');
        }
      }
      
      final File prefsFile = File(p.join(importDataDir.path, 'prefs.json'));
      await prefsFile.writeAsString(jsonEncode(prefsData));

      // b. Export YiHuaTimer data directory (including DB and assets)
      if (withData) {
        final supportDir = await getApplicationSupportDirectory();
        final Directory dataDir = Directory(AppConfig.dataPath(supportDir.path));
        if (await dataDir.exists()) {
          final Directory destDataDir = Directory(p.join(importDataDir.path, 'YiHuaTimer'));
          print('Staging data directory from ${dataDir.path} to ${destDataDir.path}');
          await _recursiveCopy(dataDir, destDataDir);
        }
      }

      // 5. Zip the directory

      // If a zip with the same name already exists, delete it
      final File existingZip = File(outZipPath);
      if (await existingZip.exists()) {
        await existingZip.delete();
      }

      // Run zipping in an isolate to prevent UI freeze
      await compute(_createZipIsolate, {'source': appCopyDir.path, 'dest': outZipPath});

      // 6. Cleanup temp folder
      await stagingDir.delete(recursive: true);

      if (kDebugMode) {
        print("Successfully exported app to: $outZipPath");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error sharing app: $e");
      }
      rethrow;
    }
  }

  /// Recursively copies a directory with detailed logging
  static Future<void> _recursiveCopy(Directory source, Directory destination) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    await for (var entity in source.list(recursive: false)) {
      final name = p.basename(entity.path);
      final destPath = p.join(destination.path, name);

      if (entity is Directory) {
        // Skip temp/meta folders when copying the main app directory
        if (name == '__yihua_import_data__' || name == '__yihua_imported__') {
          continue;
        }
        await _recursiveCopy(entity, Directory(destPath));
      } else if (entity is File) {
        // Don't copy zip artifacts if they accidentally ended up in the app folder
        if (name.endsWith('.zip')) continue;

        try {
          print('Staging file: ${entity.path} -> $destPath');
          await entity.copy(destPath);
        } catch (e) {
          print('Warning: Failed to copy file ${entity.path}: $e');
          // We continue with other files even if one fails
        }
      }
    }
  }

  /// Run in an isolate to create zip
  static void _createZipIsolate(Map<String, String> args) {
    final source = args['source']!;
    final dest = args['dest']!;
    
    final encoder = ZipFileEncoder();
    encoder.create(dest);
    encoder.addDirectory(Directory(source));
    encoder.close();
  }
}
