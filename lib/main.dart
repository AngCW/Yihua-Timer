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

Future<void> _configureInitialWindow() async {
  final prefs = await SharedPreferences.getInstance();
  // 默认使用 1920 × 1080 窗口化
  final mode = prefs.getString('window_mode') ?? 'windowed_1920';

  final isFull = await windowManager.isFullScreen();

  if (mode == 'borderless') {
    await windowManager.setFullScreen(true);
  } else {
    // If we are currently fullscreen and switching to a windowed mode,
    // we must wait for the OS to finish the style transition before resizing
    // to prevent the application from crashing
    if (isFull) {
      await windowManager.setFullScreen(false);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    switch (mode) {
      case 'windowed_1280':
        await windowManager.setSize(const Size(1280, 720));
        await windowManager.center();
        break;
      case 'windowed_1600':
        await windowManager.setSize(const Size(1600, 900));
        await windowManager.center();
        break;
      case 'windowed_1920':
        await windowManager.maximize();
        break;
      case 'windowed':
      default:
        await windowManager.setSize(const Size(1400, 900));
        await windowManager.center();
        break;
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
      title: '辩论计时器',
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
