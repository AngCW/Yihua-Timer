import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  // windowed, borderless, windowed_1280, windowed_1600, windowed_1920
  // 默认使用 1920 × 1080 窗口化
  String _windowMode = 'windowed_1920';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('window_mode');
    if (savedMode != null && mounted) {
      setState(() {
        _windowMode = savedMode;
      });
    }
  }

  Future<void> _saveSettings(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('window_mode', mode);
    await _applyWindowMode(mode);
  }

  Future<void> _applyWindowMode(String mode) async {
    if (!Platform.isWindows) return;

    switch (mode) {
      case 'borderless':
        await windowManager.setFullScreen(true);
        break;
      case 'windowed_1280':
        await windowManager.setFullScreen(false);
        await windowManager.setSize(const Size(1280, 720));
        await windowManager.center();
        break;
      case 'windowed_1600':
        await windowManager.setFullScreen(false);
        await windowManager.setSize(const Size(1600, 900));
        await windowManager.center();
        break;
      case 'windowed_1920':
        await windowManager.setFullScreen(false);
        await windowManager.setSize(const Size(1920, 1080));
        await windowManager.center();
        break;
      case 'windowed':
      default:
        await windowManager.setFullScreen(false);
        // Use a reasonable default window size
        await windowManager.setSize(const Size(1400, 900));
        await windowManager.center();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWindowModeCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowModeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '窗口模式',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '选择应用的窗口显示方式。部分选项可能需要重启应用后生效。',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _windowMode,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF4F46E5), width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(
                value: 'windowed_1920',
                child: Text('窗口化 1920 × 1080 (默认)'),
              ),
              DropdownMenuItem(
                value: 'windowed',
                child: Text('窗口化'),
              ),
              DropdownMenuItem(
                value: 'borderless',
                child: Text('无边框全屏'),
              ),
              DropdownMenuItem(
                value: 'windowed_1280',
                child: Text('窗口化 1280 × 720'),
              ),
              DropdownMenuItem(
                value: 'windowed_1600',
                child: Text('窗口化 1600 × 900'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _windowMode = value;
              });
              _saveSettings(value);
            },
          ),
          const SizedBox(height: 16),
          Text(
            '当前选择：${_getModeLabel(_windowMode)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  String _getModeLabel(String value) {
    switch (value) {
      case 'windowed_1920':
        return '窗口化 1920 × 1080 (默认)';
      case 'borderless':
        return '无边框全屏';
      case 'windowed_1280':
        return '窗口化 1280 × 720';
      case 'windowed_1600':
        return '窗口化 1600 × 900';
      case 'windowed':
      default:
        return '窗口化';
    }
  }
}


