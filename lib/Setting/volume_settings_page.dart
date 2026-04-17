import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
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
  List<String> _ringtones = ['默认铃声'];
  AudioPlayer? _bgmTestPlayer;
  AudioPlayer? _dingTestPlayer; // Separate player for ding testing
  bool _isBgmTesting = false;
  bool _isDingTesting = false;

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
                      value: _selectedDing,
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
                      value: _selectedBgm,
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
        ],
      ),
    );
  }
  
  void _showEditRingtoneDialog(BuildContext context, String ringtoneName) {
    final TextEditingController nameController = TextEditingController(text: ringtoneName);
    String? selectedFile;
    List<Map<String, dynamic>> timePoints = [
      {'minutes': 0, 'seconds': 30, 'times': 1},
      {'minutes': 0, 'seconds': 5, 'times': 1},
      {'minutes': 0, 'seconds': 0, 'times': 2},
    ];
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(40),
          child: Container(
            width: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B46C1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ringtoneName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ringtone Sound Section
                        const Text(
                          '铃声声音',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add, color: Color(0xFF6B46C1), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedFile ?? '可以拖拽文件或点击上传 (MP3)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selectedFile != null ? Colors.black : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Time Points Section
                        const Text(
                          '铃声响的:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '时间点',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...timePoints.asMap().entries.map((entry) {
                          final index = entry.key;
                          final point = entry.value;
                          final minutesController = TextEditingController(
                            text: point['minutes'].toString(),
                          );
                          final secondsController = TextEditingController(
                            text: point['seconds'].toString().padLeft(2, '0'),
                          );
                          final timesController = TextEditingController(
                            text: point['times'].toString(),
                          );
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildTimePointItem(
                              minutesController: minutesController,
                              secondsController: secondsController,
                              timesController: timesController,
                              onDelete: () {
                                setDialogState(() {
                                  timePoints.removeAt(index);
                                });
                              },
                              onChanged: () {
                                setDialogState(() {
                                  point['minutes'] = int.tryParse(minutesController.text) ?? 0;
                                  point['seconds'] = int.tryParse(secondsController.text) ?? 0;
                                  point['times'] = int.tryParse(timesController.text) ?? 1;
                                });
                              },
                            ),
                          );
                        }),
                        // Add Time Point Button
                        InkWell(
                          onTap: () {
                            setDialogState(() {
                              timePoints.add({
                                'minutes': 0,
                                'seconds': 0,
                                'times': 1,
                              });
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Color(0xFF6B46C1),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer Buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () {
                          // TODO: Save ringtone changes
                          Navigator.of(dialogContext).pop();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6B46C1),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showAddRingtoneDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    String? selectedFile;
    List<Map<String, dynamic>> timePoints = [];
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(40),
          child: Container(
            width: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B46C1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '添加铃声',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ringtone Name Section
                        const Text(
                          '铃声名称',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: '请输入铃声名称',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(color: Color(0xFF6B46C1), width: 1.2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Ringtone Sound Section
                        const Text(
                          '铃声声音',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add, color: Color(0xFF6B46C1), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedFile ?? '可以拖拽文件或点击上传 (MP3)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selectedFile != null ? Colors.black : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Time Points Section
                        const Text(
                          '铃声响的:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '时间点',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...timePoints.asMap().entries.map((entry) {
                          final index = entry.key;
                          final point = entry.value;
                          final minutesController = TextEditingController(
                            text: point['minutes'].toString(),
                          );
                          final secondsController = TextEditingController(
                            text: point['seconds'].toString().padLeft(2, '0'),
                          );
                          final timesController = TextEditingController(
                            text: point['times'].toString(),
                          );
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildTimePointItem(
                              minutesController: minutesController,
                              secondsController: secondsController,
                              timesController: timesController,
                              onDelete: () {
                                setDialogState(() {
                                  timePoints.removeAt(index);
                                });
                              },
                              onChanged: () {
                                setDialogState(() {
                                  point['minutes'] = int.tryParse(minutesController.text) ?? 0;
                                  point['seconds'] = int.tryParse(secondsController.text) ?? 0;
                                  point['times'] = int.tryParse(timesController.text) ?? 1;
                                });
                              },
                            ),
                          );
                        }),
                        // Add Time Point Button
                        InkWell(
                          onTap: () {
                            setDialogState(() {
                              timePoints.add({
                                'minutes': 0,
                                'seconds': 0,
                                'times': 1,
                              });
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Color(0xFF6B46C1),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer Buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () {
                          if (nameController.text.trim().isNotEmpty) {
                            setState(() {
                              _ringtones.add(nameController.text.trim());
                            });
                            Navigator.of(dialogContext).pop();
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6B46C1),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimePointItem({
    required TextEditingController minutesController,
    required TextEditingController secondsController,
    required TextEditingController timesController,
    VoidCallback? onDelete,
    VoidCallback? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Minutes input
          SizedBox(
            width: 50,
            child: TextFormField(
              controller: minutesController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onChanged: (_) => onChanged?.call(),
              onEditingComplete: () {
                if (minutesController.text.isEmpty) {
                  minutesController.text = '0';
                  onChanged?.call();
                }
              },
              onTapOutside: (_) {
                if (minutesController.text.isEmpty) {
                  minutesController.text = '0';
                  onChanged?.call();
                }
              },
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF6B46C1), width: 1.2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ':',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          // Seconds input
          SizedBox(
            width: 50,
            child: TextFormField(
              controller: secondsController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onChanged: (_) {
                onChanged?.call();
              },
              onEditingComplete: () {
                if (secondsController.text.isEmpty) {
                  secondsController.text = '00';
                  onChanged?.call();
                } else {
                  // Pad with zero if single digit
                  final value = int.tryParse(secondsController.text) ?? 0;
                  secondsController.text = value.toString().padLeft(2, '0');
                  onChanged?.call();
                }
              },
              onTapOutside: (_) {
                if (secondsController.text.isEmpty) {
                  secondsController.text = '00';
                  onChanged?.call();
                } else {
                  // Pad with zero if single digit
                  final value = int.tryParse(secondsController.text) ?? 0;
                  secondsController.text = value.toString().padLeft(2, '0');
                  onChanged?.call();
                }
              },
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF6B46C1), width: 1.2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '时, 响',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 8),
          // Times input
          SizedBox(
            width: 50,
            child: TextFormField(
              controller: timesController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onChanged: (_) => onChanged?.call(),
              onEditingComplete: () {
                if (timesController.text.isEmpty) {
                  timesController.text = '1';
                  onChanged?.call();
                }
              },
              onTapOutside: (_) {
                if (timesController.text.isEmpty) {
                  timesController.text = '1';
                  onChanged?.call();
                }
              },
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF6B46C1), width: 1.2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '下',
            style: TextStyle(fontSize: 14),
          ),
          const Spacer(),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

