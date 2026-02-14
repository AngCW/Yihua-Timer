import 'package:flutter/material.dart';
import '../Dashboard/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DebateTimerApp());
}

class DebateTimerApp extends StatelessWidget {
  const DebateTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '辩论计时器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: const Color(0xFF6B46C1),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        fontFamily: 'Microsoft YaHei',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B46C1),
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

