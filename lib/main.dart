import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'Dashboard/screens/dashboard_screen.dart';
import 'database/app_database.dart';

late AppDatabase database;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // 默认使用 1920 × 1080 窗口化
  final mode = prefs.getString('window_mode') ?? 'windowed_1920';
  final wasMaximized = prefs.getBool('is_maximized') ?? (mode == 'windowed_1920');

  final isFull = await windowManager.isFullScreen();

  if (mode == 'borderless') {
    await windowManager.setFullScreen(true);
  } else {
    if (isFull) {
      await windowManager.setFullScreen(false);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (wasMaximized) {
      await windowManager.maximize();
    } else {
      switch (mode) {
        case 'windowed_1280':
          await windowManager.setSize(const Size(1280, 720));
          await windowManager.center();
          break;
        case 'windowed_1600':
          await windowManager.setSize(const Size(1600, 900));
          await windowManager.center();
          break;
        case 'windowed':
        default:
          await windowManager.setSize(const Size(1400, 900));
          await windowManager.center();
          break;
      }
    }
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
        cardTheme: CardTheme(
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
