import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import '../Services/update_service.dart';
import '../Services/share_app_service.dart';
import '../main.dart'; // To access global database

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  // windowed, borderless, windowed_1280, windowed_1600, windowed_1920
  // 默认使用 1920 × 1080 窗口化
  String _windowMode = 'windowed_1920';

  bool _isSharing = false;

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

    final isFull = await windowManager.isFullScreen();

    if (mode == 'borderless') {
      await windowManager.setFullScreen(true);
      return;
    }

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
        // Maximize fits the work area without clipping under the taskbar
        await windowManager.maximize();
        break;
      case 'windowed':
      default:
        // Use a reasonable default window size
        await windowManager.setSize(const Size(1400, 900));
        await windowManager.center();
        break;
    }
  }

  Future<void> _handleShareApp(bool withData) async {
    setState(() {
      _isSharing = true;
    });
    try {
      await ShareAppService.shareApp(withData: withData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('软件分享成功，已保存到下载文件夹！(Saved to Downloads)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  void _showShareOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('分享选项'),
          content: const Text('请选择您想要分享的内容：\n\n- 软件：仅分享软件程序本身。\n- 软件+数据：分享软件程序以及您当前的配置、快捷键和赛事数据。如果分享给其他人，他们可以直接使用您当前的配置。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleShareApp(false); // only software
              },
              child: const Text('仅分享软件'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleShareApp(true); // with data
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
              ),
              child: const Text('分享软件+数据'),
            ),
          ],
        );
      },
    );
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
            const SizedBox(height: 24),
            _buildShareAppCard(),
            const SizedBox(height: 24),
            _buildUpdateCard(),
            const SizedBox(height: 24),
            _buildCleanupCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4F46E5).withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '软件更新 (Updates)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '检查是否有新版本的辩论计时器。',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: _handleCheckForUpdate,
              icon: const Icon(Icons.update, size: 20),
              label: const Text('检查更新'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckForUpdate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final updateInfo = await UpdateService.checkForUpdate();
      if (mounted) Navigator.pop(context); // Close loading

      if (updateInfo != null) {
        if (mounted) {
          _showUpdateDialog(updateInfo);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('当前已是最新版本 (You are on the latest version)')),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('检查更新失败 (Update check failed): $e')),
        );
      }
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('新版本可用: v${info.version}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('更新日志 (Changelog):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(info.changelog),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('以后再说 (Later)'),
          ),
          ElevatedButton(
            onPressed: () {
              UpdateService.launchUpdateUrl(info.downloadUrl);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            child: const Text('立即去更新 (Update Now)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanupCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.shade100,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '数据清理 (Dangerous)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '清除所有赛事数据、配置、图片和音频。此操作不可撤销，执行后应用将自动关闭，请手动重新启动。',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _showClearDataConfirmation,
              icon: const Icon(Icons.delete_forever_rounded, size: 20),
              label: const Text('完全清除所有数据并退出'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认完全清除？'),
        content: const Text('这将删除所有赛事记录、背景图、音频和设置。您确定要执行此操作吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleClearAllData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确定清除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleClearAllData() async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final dataDir = Directory(p.join(supportDir.path, 'YiHuaTimer'));
      
      // Release database lock on Windows
      await database.close();
      // Give the OS a moment to release file handles
      await Future.delayed(const Duration(milliseconds: 500));

      if (await dataDir.exists()) {
        try {
          await dataDir.delete(recursive: true);
        } catch (e) {
          // Fallback if root folder deletion fails: delete what can be deleted
          await for (var entity in dataDir.list(recursive: true)) {
            try {
              if (entity is File) await entity.delete();
            } catch (_) {}
          }
          // Try root again after cleaning interior
          try { await dataDir.delete(recursive: true); } catch (_) {}
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('清理完成'),
            content: const Text('所有数据已成功清除。应用现在将关闭，请手动重启以应用更改。'),
            actions: [
              FilledButton(
                onPressed: () => exit(0),
                child: const Text('退出应用'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清理失败 (Cleanup Failed): $e'),
            duration: const Duration(seconds: 10),
            action: SnackBarAction(label: '确定', onPressed: () {}),
          ),
        );
      }
    }
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
                child: Text('最大化窗口 (默认)'),
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
        return '最大化窗口 (默认)';
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

  Widget _buildShareAppCard() {
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
            '分享软件',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '将应用及其数据打包为 ZIP 文件，以便分享给他人。文件将保存在“下载”文件夹中。',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isSharing ? null : _showShareOptionsDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '打包并分享软件',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
