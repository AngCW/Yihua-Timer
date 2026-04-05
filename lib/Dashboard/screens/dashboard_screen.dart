import 'package:debate_timer/EventManager/event_manager_page.dart';
import 'package:flutter/material.dart';
import '../widgets/navigation_sidebar.dart';
import '../widgets/recent_events_section.dart';
import '../widgets/create_event_section.dart';
import '../widgets/shortcuts_section.dart';
import '../widgets/event_schedule_sidebar.dart';
import '../widgets/search_bar.dart';
import '../../CreateEvent/create_event_form.dart';
import '../../../Setting/settings_page.dart';
import '../../Timer/timer_page.dart';
import '../../Services/update_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedNavIndex = 0;
  bool _isDownloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    // Auto-check for updates on launch
    _checkUpdateOnLaunch();
  }

  Future<void> _checkUpdateOnLaunch() async {
    // Small delay to ensure UI is ready
    await Future.delayed(const Duration(seconds: 1));
    try {
      final info = await UpdateService.checkForUpdate();
      if (info != null && mounted) {
        _showUpdateDialog(info);
      }
    } catch (e) {
      print('Auto-update check failed: $e');
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: !_isDownloading,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('发现新版本: v${info.version}'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('更新日志 (Changelog):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      info.changelog,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ),
                if (_isDownloading) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _downloadProgress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${(_downloadProgress * 100).toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text('正在下载更新包 (Downloading update)...',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (!_isDownloading) ...[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('以后再说 (Later)'),
              ),
              ElevatedButton(
                onPressed: () => _handleDownloadAndInstall(info, setDialogState),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                child: const Text('下载并安装 (Download & Install)',
                    style: TextStyle(color: Colors.white)),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('下载中，请稍候...', style: TextStyle(color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDownloadAndInstall(UpdateInfo info, StateSetter setDialogState) async {
    setState(() => _isDownloading = true);
    setDialogState(() => _isDownloading = true);

    try {
      final file = await UpdateService.downloadUpdate(info, (progress) {
        setState(() => _downloadProgress = progress);
        setDialogState(() => _downloadProgress = progress);
      });

      if (file != null) {
        if (mounted) Navigator.pop(context);
        await UpdateService.installUpdate(file);
      } else {
        throw Exception('File download failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败 (Download failed): $e')),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebar(
            selectedIndex: _selectedNavIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedNavIndex = index;
              });
            },
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF3F4F6),
              child: Column(
                children: [
                  if (_selectedNavIndex != 1 && _selectedNavIndex != 4)
                    const SearchBarWidget(),
                  Expanded(
                    child: KeyedSubtree(
                      key: ValueKey(_selectedNavIndex),
                      child: _buildMainContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const EventScheduleSidebar(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedNavIndex) {
      case 0:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecentEventsSection(
                onViewAll: () {
                  setState(() {
                    _selectedNavIndex = 2;
                  });
                },
              ),
              const SizedBox(height: 40),
              const CreateEventSection(),
              const SizedBox(height: 40),
              const ShortcutsSection(),
            ],
          ),
        );
      case 1:
        return const CreateEventPage();

      case 2:
        return const EventManagerPage();
      case 3:
        return const TimerPage();
      case 4:
        return SettingsPage(
          onBack: () {
            setState(() {
              _selectedNavIndex = 0;
            });
          },
        );
      default:
        return const Center(
          child: Text(
            '该功能正在开发中...',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
        );
    }
  }
}
