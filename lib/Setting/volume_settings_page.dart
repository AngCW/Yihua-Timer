import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../main.dart';
import 'timer_template_settings_page.dart';
import '../app_config.dart';

class VolumeSettingsPage extends StatefulWidget {
  const VolumeSettingsPage({super.key});

  @override
  State<VolumeSettingsPage> createState() => _VolumeSettingsPageState();
}

class _VolumeSettingsPageState extends State<VolumeSettingsPage> {
  double _ringtoneVolume = 0.7;
  double _backgroundMusicVolume = 0.5;
  List<BgmData> _bgms = [];
  List<DingAudioData> _dings = [];
  BgmData? _selectedBgm;
  DingAudioData? _selectedDing;

  AudioPlayer? _bgmTestPlayer;
  AudioPlayer? _dingTestPlayer; // Separate player for ding testing
  bool _isBgmTesting = false;
  bool _isDingTesting = false;
  bool _isDingDelayTesting = false;
  double _testIntervalSeconds = 0.5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAudioData();
  }

  @override
  void dispose() {
    _bgmTestPlayer?.stop();
    _bgmTestPlayer?.dispose();
    _dingTestPlayer?.stop();
    _dingTestPlayer?.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ringtoneVolume = prefs.getDouble('ringtone_volume') ?? 0.7;
      _backgroundMusicVolume = prefs.getDouble('bgm_volume') ?? 0.5;
    });
  }

  Future<void> _saveVolume(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  Future<void> _loadAudioData() async {
    final bgms = await database.select(database.bgm).get();
    final dings = await database.select(database.dingAudio).get();
    if (!mounted) return;
    setState(() {
      _bgms = bgms;
      _dings = dings;
      if (_bgms.isNotEmpty) _selectedBgm = _bgms.first;
      if (_dings.isNotEmpty) _selectedDing = _dings.first;
    });
  }

  /// Toggles BGM testing
  Future<void> _toggleBgmTest() async {
    if (_isBgmTesting) {
      await _bgmTestPlayer?.stop();
      await _bgmTestPlayer?.dispose();
      _bgmTestPlayer = null;
      setState(() => _isBgmTesting = false);
    } else {
      if (_selectedBgm == null) return;
      
      final supportDir = await getApplicationSupportDirectory();
      final path = p.join(AppConfig.dataPath(supportDir.path), 'bgm', _selectedBgm!.bgmName);
      
      if (File(path).existsSync()) {
        final player = AudioPlayer();
        _bgmTestPlayer = player;
        await player.setVolume(_backgroundMusicMusicVolume);
        await player.setReleaseMode(ReleaseMode.loop);
        await player.play(DeviceFileSource(path));
        setState(() => _isBgmTesting = true);
      }
    }
  }

  /// Toggles Ding testing
  Future<void> _toggleDingTest() async {
    if (_isDingTesting) {
      await _dingTestPlayer?.stop();
      await _dingTestPlayer?.dispose();
      _dingTestPlayer = null;
      setState(() => _isDingTesting = false);
    } else {
      if (_selectedDing == null) return;
      
      final supportDir = await getApplicationSupportDirectory();
      final path = p.join(AppConfig.dataPath(supportDir.path), 'ding', _selectedDing!.dingName);
      
      if (File(path).existsSync()) {
        final player = AudioPlayer();
        _dingTestPlayer = player;
        await player.setVolume(_ringtoneVolume);
        await player.setReleaseMode(ReleaseMode.loop); // Loop for testing purposes
        await player.play(DeviceFileSource(path));
        setState(() => _isDingTesting = true);
      }
    }
  }

  // Define these as getters/setters for volume update
  double get _backgroundMusicMusicVolume => _backgroundMusicVolume;
  set _backgroundMusicMusicVolume(double val) {
    _backgroundMusicVolume = val;
    _bgmTestPlayer?.setVolume(val);
  }

  set ringtoneVolume(double val) {
    _ringtoneVolume = val;
    _dingTestPlayer?.setVolume(val);
  }

  Future<void> _testDingDelay() async {
    if (_selectedDing == null || _isDingDelayTesting) return;
    
    setState(() => _isDingDelayTesting = true);
    
    final supportDir = await getApplicationSupportDirectory();
    final path = p.join(AppConfig.dataPath(supportDir.path), 'ding', _selectedDing!.dingName);
    
    if (File(path).existsSync()) {
      // Play 3 dings with dynamic interval to test for delay consistency
      for (int i = 0; i < 3; i++) {
        final player = AudioPlayer();
        player.setVolume(_ringtoneVolume);
        await player.play(DeviceFileSource(path));
        // We don't wait for completion here to simulate the real-world scenario
        // but we wait for the interval.
        player.onPlayerComplete.listen((_) => player.dispose());
        await Future.delayed(Duration(milliseconds: (_testIntervalSeconds * 1000).toInt()));
      }
    }
    
    if (mounted) setState(() => _isDingDelayTesting = false);
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
            _buildVolumeCard(
              title: '提示音',
              value: _ringtoneVolume,
              onChanged: (value) {
                setState(() {
                  ringtoneVolume = value;
                });
                _saveVolume('ringtone_volume', value);
              },
              topWidget: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<DingAudioData>(
                      initialValue: _selectedDing,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: '测试提示音',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: _dings.map((d) => DropdownMenuItem(value: d, child: Text(d.dingName, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) => setState(() => _selectedDing = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _toggleDingTest,
                    icon: Icon(_isDingTesting ? Icons.stop : Icons.play_arrow, size: 16),
                    label: Text(_isDingTesting ? '停止' : '测试'),
                    style: TextButton.styleFrom(
                      foregroundColor: _isDingTesting ? Colors.red : const Color(0xFF6B46C1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _showDingManagementDialog,
                    icon: const Icon(Icons.settings_suggest_outlined, size: 16),
                    label: const Text('管理'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B46C1),
                    ),
                  ),
                ],
              ),
              bottomWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '延时测试 (连响测试)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '测试是否存在播放延迟导致的重叠',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _isDingDelayTesting ? null : _testDingDelay,
                        icon: _isDingDelayTesting 
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.timer_outlined, size: 16),
                        label: Text(_isDingDelayTesting ? '测试中...' : '开始测试'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B46C1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 140,
                        child: Text(
                          '连响间隔: ${_testIntervalSeconds.toStringAsFixed(1)}秒',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _testIntervalSeconds,
                          min: 0.1,
                          max: 2.0,
                          divisions: 19,
                          label: '${_testIntervalSeconds.toStringAsFixed(1)}s',
                          onChanged: _isDingDelayTesting ? null : (val) => setState(() => _testIntervalSeconds = val),
                          activeColor: const Color(0xFF6B46C1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Background Music Volume Section
            _buildVolumeCard(
              title: '背景音乐',
              value: _backgroundMusicVolume,
              onChanged: (value) {
                setState(() {
                  _backgroundMusicMusicVolume = value;
                });
                _saveVolume('bgm_volume', value);
              },
              topWidget: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<BgmData>(
                      initialValue: _selectedBgm,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: '测试 BGM',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: _bgms.map((b) => DropdownMenuItem(value: b, child: Text(b.bgmName, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) => setState(() => _selectedBgm = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _toggleBgmTest,
                    icon: Icon(_isBgmTesting ? Icons.stop : Icons.play_arrow, size: 16),
                    label: Text(_isBgmTesting ? '停止' : '测试'),
                    style: TextButton.styleFrom(
                      foregroundColor: _isBgmTesting ? Colors.red : const Color(0xFF6B46C1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _showBgmManagementDialog,
                    icon: const Icon(Icons.settings_suggest_outlined, size: 16),
                    label: const Text('管理'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B46C1),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Timer template & ringtone design section (moved from 铃声设计)
            const TimerTemplateSettingsPage(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeCard({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
    Widget? topWidget,
    Widget? bottomWidget,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          if (topWidget != null) ...[
            const SizedBox(height: 20),
            topWidget,
          ],
          const SizedBox(height: 20),
          Slider(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6B46C1),
            inactiveColor: Colors.grey.shade300,
            min: 0.0,
            max: 1.0,
          ),
          if (bottomWidget != null) ...[
            const SizedBox(height: 12),
            bottomWidget,
          ],
        ],
      ),
    );
  }
  
  // --- Management Dialogs ---

  void _showBgmManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('管理背景音乐'),
              IconButton(
                onPressed: () async {
                  await _uploadBgm();
                  setDialogState(() {});
                },
                icon: const Icon(Icons.add, color: Color(0xFF6B46C1)),
                tooltip: '添加 BGM',
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 400,
            child: _bgms.isEmpty
                ? const Center(child: Text('暂无 BGM'))
                : ListView.builder(
                    itemCount: _bgms.length,
                    itemBuilder: (context, index) {
                      final bgm = _bgms[index];
                      return ListTile(
                        title: Text(bgm.bgmName, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showRenameDialog(
                                context: context,
                                currentName: bgm.bgmName,
                                onRename: (newName) async {
                                  await _renameBgm(bgm, newName);
                                  setDialogState(() {});
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              onPressed: () => _confirmDeleteBgm(bgm, () {
                                setDialogState(() {});
                              }),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
          ],
        ),
      ),
    );
  }

  void _showDingManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('管理提示音'),
              IconButton(
                onPressed: () async {
                  await _uploadDingAudio();
                  setDialogState(() {});
                },
                icon: const Icon(Icons.add, color: Color(0xFF6B46C1)),
                tooltip: '添加提示音',
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 400,
            child: _dings.isEmpty
                ? const Center(child: Text('暂无提示音'))
                : ListView.builder(
                    itemCount: _dings.length,
                    itemBuilder: (context, index) {
                      final ding = _dings[index];
                      return ListTile(
                        title: Text(ding.dingName, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showRenameDialog(
                                context: context,
                                currentName: ding.dingName,
                                onRename: (newName) async {
                                  await _renameDing(ding, newName);
                                  setDialogState(() {});
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              onPressed: () => _confirmDeleteDing(ding, () {
                                setDialogState(() {});
                              }),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog({
    required BuildContext context,
    required String currentName,
    required Function(String) onRename,
  }) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                onRename(newName);
              }
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6B46C1)),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // --- BGM Operations ---

  Future<void> _uploadBgm() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      try {
        final supportDir = await getApplicationSupportDirectory();
        final bgmDir = Directory(p.join(AppConfig.dataPath(supportDir.path), 'bgm'));
        if (!await bgmDir.exists()) await bgmDir.create(recursive: true);

        final targetPath = p.join(bgmDir.path, fileName);
        await file.copy(targetPath);

        await database.into(database.bgm).insert(BgmCompanion.insert(bgmName: fileName));
        await _loadAudioData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('上传失败: $e')));
        }
      }
    }
  }

  Future<void> _renameBgm(BgmData bgm, String newName) async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final bgmDir = Directory(p.join(AppConfig.dataPath(supportDir.path), 'bgm'));
      final oldFile = File(p.join(bgmDir.path, bgm.bgmName));
      final newFile = File(p.join(bgmDir.path, newName));

      if (await oldFile.exists()) {
        await oldFile.rename(newFile.path);
      }

      await (database.update(database.bgm)..where((t) => t.id.equals(bgm.id)))
          .write(BgmCompanion(bgmName: drift.Value(newName)));
      
      await _loadAudioData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('重命名失败: $e')));
      }
    }
  }

  Future<void> _confirmDeleteBgm(BgmData bgm, VoidCallback onSuccess) async {
    // Check usage
    final usages = await (database.select(database.page)..where((t) => t.bgmId.equals(bgm.id))).get();
    
    if (!mounted) return;
    
    String message = '确定要删除 "${bgm.bgmName}" 吗？';
    if (usages.isNotEmpty) {
      message += '\n\n此 BGM 正在被 ${usages.length} 个页面使用。删除后这些页面将没有背景音乐。';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBgm(bgm);
              onSuccess();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBgm(BgmData bgm) async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final bgmDir = Directory(p.join(AppConfig.dataPath(supportDir.path), 'bgm'));
      final file = File(p.join(bgmDir.path, bgm.bgmName));

      if (await file.exists()) {
        await file.delete();
      }

      // Nullify references in page table (drift handle references if set up, but let's be explicit if needed)
      // Actually, standard behavior is usually SET NULL if configured, but we'll manually ensure it if it doesn't.
      await (database.update(database.page)..where((t) => t.bgmId.equals(bgm.id)))
          .write(PageCompanion(bgmId: const drift.Value(null)));

      await (database.delete(database.bgm)..where((t) => t.id.equals(bgm.id))).go();
      
      await _loadAudioData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  // --- Ding Operations ---

  Future<void> _uploadDingAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      try {
        final supportDir = await getApplicationSupportDirectory();
        final dingDir = Directory(p.join(AppConfig.dataPath(supportDir.path), 'ding'));
        if (!await dingDir.exists()) await dingDir.create(recursive: true);

        final targetPath = p.join(dingDir.path, fileName);
        await file.copy(targetPath);

        await database.into(database.dingAudio).insert(DingAudioCompanion.insert(dingName: fileName));
        await _loadAudioData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('上传失败: $e')));
        }
      }
    }
  }

  Future<void> _renameDing(DingAudioData ding, String newName) async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final dingDir = Directory(p.join(AppConfig.dataPath(supportDir.path), 'ding'));
      final oldFile = File(p.join(dingDir.path, ding.dingName));
      final newFile = File(p.join(dingDir.path, newName));

      if (await oldFile.exists()) {
        await oldFile.rename(newFile.path);
      }

      await (database.update(database.dingAudio)..where((t) => t.id.equals(ding.id)))
          .write(DingAudioCompanion(dingName: drift.Value(newName)));
      
      await _loadAudioData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('重命名失败: $e')));
      }
    }
  }

  Future<void> _confirmDeleteDing(DingAudioData ding, VoidCallback onSuccess) async {
    // Check usage in timer_template
    final usages = await (database.select(database.timerTemplate)..where((t) => t.dingAudioId.equals(ding.id))).get();
    
    if (!mounted) return;
    
    String message = '确定要删除 "${ding.dingName}" 吗？';
    if (usages.isNotEmpty) {
      message += '\n\n此提示音正在被 ${usages.length} 个计时器模板使用。删除后这些模板将没有提示音。';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteDing(ding);
              onSuccess();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDing(DingAudioData ding) async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final dingDir = Directory(p.join(AppConfig.dataPath(supportDir.path), 'ding'));
      final file = File(p.join(dingDir.path, ding.dingName));

      if (await file.exists()) {
        await file.delete();
      }

      // Nullify references in timer_template table
      await (database.update(database.timerTemplate)..where((t) => t.dingAudioId.equals(ding.id)))
          .write(TimerTemplateCompanion(dingAudioId: const drift.Value(null)));

      await (database.delete(database.dingAudio)..where((t) => t.id.equals(ding.id))).go();
      
      await _loadAudioData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }
}

