import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'app_config.dart';
import 'Dashboard/screens/dashboard_screen.dart';
import 'database/app_database.dart';

late AppDatabase database;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read the real version from pubspec.yaml before any paths are resolved.
  await AppConfig.init();

  await _importSharedDataIfNeeded();

  // Initialize database
  database = AppDatabase();

  // Initialize window manager and apply saved window mode (Windows only)
  await windowManager.ensureInitialized();
  await _configureInitialWindow();

  runApp(const DebateTimerApp());
}

class WindowStateListener extends WindowListener {
  @override
  void onWindowMaximize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_maximized', true);
  }

  @override
  void onWindowUnmaximize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_maximized', false);
  }
}

Future<void> _configureInitialWindow() async {
  final prefs = await SharedPreferences.getInstance();

  // Register the listener to track future changes
  windowManager.addListener(WindowStateListener());

  final mode = prefs.getString('window_mode') ?? 'windowed_1920';

  if (mode == 'borderless') {
    await windowManager.setFullScreen(true);
  } else {
    // Always maximize on startup for the default windowed mode
    await windowManager.maximize();
  }

  await windowManager.show();
  await windowManager.focus();
}

class DebateTimerApp extends StatelessWidget {
  const DebateTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YiHuaTimer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF4F46E5),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        fontFamily: 'Microsoft YaHei',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

Future<bool> _directoryHasFiles(Directory dir) async {
  try {
    return !(await dir.list(recursive: false).isEmpty);
  } catch (_) {}
  return false;
}

Future<bool?> _showImportPrompt() {
  final completer = Completer<bool?>();

  runApp(
    MaterialApp(
      title: 'YiHuaTimer 数据导入',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: AlertDialog(
              title: const Text('发现新的导入数据', style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text(
                  '检测到此程序附带了新的赛事数据和配置。\n'
                  '但是，您的系统上已经存在旧的 YiHuaTimer 数据。\n\n'
                  '您是否要完全清除旧数据，并导入这个包里的新数据？\n'
                  '(注：如果选择“否”，将保留您的旧数据并自动永久忽略此次导入)'),
              actions: [
                TextButton(
                  onPressed: () => completer.complete(false),
                  child: const Text('否，保留旧数据'),
                ),
                ElevatedButton(
                  onPressed: () => completer.complete(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('是，覆盖所有数据'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  return completer.future;
}

Future<void> _importSharedDataIfNeeded() async {
  if (!Platform.isWindows) return;

  try {
    final appDir = File(Platform.resolvedExecutable).parent;
    final importDir = Directory(p.join(appDir.path, '__yihua_import_data__'));

    if (await importDir.exists()) {
      if (kDebugMode) {
        print('Found import data folder. Checking conditions...');
      }

      final supportDir = await getApplicationSupportDirectory();
      final targetAppFolder = Directory(AppConfig.dataPath(supportDir.path));

      bool shouldImport = true;

      // Check if target directory already has data
      if (await targetAppFolder.exists() && await _directoryHasFiles(targetAppFolder)) {
        final userChoice = await _showImportPrompt();
        if (userChoice != true) {
          shouldImport = false;
        }
      }

      if (shouldImport) {
        // 1. Import SharedPreferences
        final prefsFile = File(p.join(importDir.path, 'prefs.json'));
      if (await prefsFile.exists()) {
        final prefs = await SharedPreferences.getInstance();
        final String content = await prefsFile.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);

        for (final entry in data.entries) {
          final key = entry.key;
          final value = entry.value;
          if (value is String)
            await prefs.setString(key, value);
          else if (value is int)
            await prefs.setInt(key, value);
          else if (value is double)
            await prefs.setDouble(key, value);
          else if (value is bool)
            await prefs.setBool(key, value);
          else if (value is List)
            await prefs.setStringList(key, (value).cast<String>());
        }
      }

      // 2. Import YiHuaTimer data directory (Database + Assets)
      final importDataChildDir =
          Directory(p.join(importDir.path, 'YiHuaTimer'));

      if (await importDataChildDir.exists()) {
        print(
            'Import folder "YiHuaTimer" found. Performing clean overwrite...');
        // [CLEAN OVERWRITE] Delete existing data to ensure a fresh start as requested by user
        if (await targetAppFolder.exists()) {
          try {
            await targetAppFolder.delete(recursive: true);
          } catch (e) {
            print('Warning: Failed to delete existing data folder: $e');
          }
        }
        await targetAppFolder.create(recursive: true);

        // Copy everything from import folder to app support folder
        print(
            'Copying data from ${importDataChildDir.path} to ${targetAppFolder.path}');
        await _copyDirectory(importDataChildDir, targetAppFolder);
      } else {
        print(
            'Import folder "YiHuaTimer" NOT found. Looking for legacy db file...');
        // Fallback for older ZIPs that only have the .db file in the root of importDir
        final dbFile = File(p.join(importDir.path, 'yihua_timer.db'));
        if (await dbFile.exists()) {
          if (!await targetAppFolder.exists()) {
            await targetAppFolder.create(recursive: true);
          }
          final targetDbFile =
              File(p.join(targetAppFolder.path, 'yihua_timer.db'));
          await dbFile.copy(targetDbFile.path);
          print('Legacy db file imported.');
        }
      }
      
      } // End of shouldImport check

      // 3. Rename import folder to prevent re-importing on next launch
      try {
        await importDir.rename(p.join(appDir.path, '__yihua_imported__'));
      } catch (e) {
        // Fallback: delete if rename fails
        await importDir.delete(recursive: true);
      }

      if (kDebugMode) {
        print('Shared data successfully imported!');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error during shared data import: $e');
    }
  }
}

/// Recursively copies a directory with logging
Future<void> _copyDirectory(Directory source, Directory destination) async {
  if (!await destination.exists()) {
    await destination.create(recursive: true);
  }

  await for (var entity in source.list(recursive: false)) {
    final name = p.basename(entity.path);
    final destPath = p.join(destination.path, name);

    if (entity is Directory) {
      await _copyDirectory(entity, Directory(destPath));
    } else if (entity is File) {
      try {
        print('Importing file: ${entity.path} -> $destPath');
        await entity.copy(destPath);
      } catch (e) {
        print('Error importing file ${entity.path}: $e');
      }
    }
  }
}
