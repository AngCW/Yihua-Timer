import 'dart:async' as async;
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/app_database.dart';
import '../main.dart';
import 'timer_template_settings_page.dart';

class VolumeSettingsPage extends StatefulWidget {
  const VolumeSettingsPage({super.key});

  @override
  State<VolumeSettingsPage> createState() => _VolumeSettingsPageState();
}

class _VolumeSettingsPageState extends State<VolumeSettingsPage> {
  double _ringtoneVolume = 0.7;
  double _backgroundMusicVolume = 0.5;
  List<String> _ringtones = ['默认铃声'];
  List<EventData> _events = [];
  EventData? _selectedEvent;
  AudioPlayer? _bgmTestPlayer;
  async.Timer? _testStopTimer;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _testStopTimer?.cancel();
    _bgmTestPlayer?.stop();
    _bgmTestPlayer?.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final query = database.select(database.event)
      ..orderBy([
        (t) => drift.OrderingTerm(
              expression: t.startDate,
              mode: drift.OrderingMode.asc,
            ),
      ]);
    final list = await query.get();
    if (!mounted) return;
    setState(() {
      _events = list;
      if (_events.isNotEmpty) {
        _selectedEvent = _events.first;
      }
    });
  }

  /// Runs a 10-second audio test: plays background music and one ding at current volumes.
  Future<void> _runAudioTest() async {
    final event = _selectedEvent;
    if (event == null) return;

    _testStopTimer?.cancel();
    await _bgmTestPlayer?.stop();
    await _bgmTestPlayer?.dispose();
    _bgmTestPlayer = null;

    final supportDir = await getApplicationSupportDirectory();
    final basePath = supportDir.path;

    // Resolve BGM: prefer a page BGM from this event's flows
    String? bgmPath;
    final flows = await (database.select(database.flow)
          ..where((t) => t.eventId.equals(event.id)))
        .get();
    for (final flow in flows) {
      final pages = await (database.select(database.page)
            ..where((t) =>
                t.flowId.equals(flow.id) & t.bgmId.isNotNull()))
        .get();
      if (pages.isNotEmpty && pages.first.bgmId != null) {
        final bgms = await (database.select(database.bgm)
              ..where((b) => b.id.equals(pages.first.bgmId!)))
            .get();
        if (bgms.isNotEmpty) {
          final path = p.join(basePath, 'YiHuaTimer', 'bgm', bgms.first.bgmName);
          if (File(path).existsSync()) {
            bgmPath = path;
            break;
          }
        }
      }
    }
    if (bgmPath == null) {
      final anyBgm = await database.select(database.bgm).get();
      for (final b in anyBgm) {
        final path = p.join(basePath, 'YiHuaTimer', 'bgm', b.bgmName);
        if (File(path).existsSync()) {
          bgmPath = path;
          break;
        }
      }
    }

    // Resolve ding: prefer a timer template ding from this event
    String? dingPath;
    for (final flow in flows) {
      final pages = await (database.select(database.page)
            ..where((t) => t.flowId.equals(flow.id)))
        .get();
      for (final page in pages) {
        final timers = await (database.select(database.timer)
              ..where((t) => t.pageId.equals(page.id)))
            .get();
        for (final timer in timers) {
          if (timer.timerTemplateId == null) continue;
          final templates = await (database.select(database.timerTemplate)
                ..where((t) => t.id.equals(timer.timerTemplateId!) &
                    t.dingAudioId.isNotNull()))
            .get();
          if (templates.isNotEmpty && templates.first.dingAudioId != null) {
            final dings = await (database.select(database.dingAudio)
                  ..where((d) => d.id.equals(templates.first.dingAudioId!)))
                .get();
            if (dings.isNotEmpty) {
              final path =
                  p.join(basePath, 'YiHuaTimer', 'ding', dings.first.dingName);
              if (File(path).existsSync()) {
                dingPath = path;
                break;
              }
            }
          }
        }
        if (dingPath != null) break;
      }
      if (dingPath != null) break;
    }
    if (dingPath == null) {
      final anyDing = await (database.select(database.dingAudio)).get();
      for (final d in anyDing) {
        final path = p.join(basePath, 'YiHuaTimer', 'ding', d.dingName);
        if (File(path).existsSync()) {
          dingPath = path;
          break;
        }
      }
    }

    // Play BGM for 10 seconds (loop)
    if (bgmPath != null) {
      final bgmPlayer = AudioPlayer();
      _bgmTestPlayer = bgmPlayer;
      await bgmPlayer.setVolume(_backgroundMusicVolume);
      await bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await bgmPlayer.play(DeviceFileSource(bgmPath));
    }

    // Play one ding at ringtone volume
    if (dingPath != null) {
      final dingPlayer = AudioPlayer();
      await dingPlayer.setVolume(_ringtoneVolume);
      dingPlayer.play(DeviceFileSource(dingPath));
      dingPlayer.onPlayerComplete.listen((_) => dingPlayer.dispose());
    }

    // Stop BGM after 10 seconds
    _testStopTimer = async.Timer(const Duration(seconds: 10), () async {
      if (_bgmTestPlayer != null) {
        await _bgmTestPlayer!.stop();
        await _bgmTestPlayer!.dispose();
        if (mounted) setState(() => _bgmTestPlayer = null);
      }
      _testStopTimer = null;
    });
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
            // Ringtone Volume Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        '测试赛事：',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<EventData>(
                          value: _selectedEvent,
                          isExpanded: true,
                          menuMaxHeight: 220,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          items: _events
                              .map(
                                (e) => DropdownMenuItem<EventData>(
                                  value: e,
                                  child: Text(
                                    e.eventName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedEvent = val;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _selectedEvent == null
                      ? null
                      : () => _runAudioTest(),
                  icon: const Icon(Icons.volume_up, size: 16),
                  label: const Text('音频测试'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B46C1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildVolumeCard(
              title: '铃声',
              value: _ringtoneVolume,
              onChanged: (value) {
                setState(() {
                  _ringtoneVolume = value;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Background Music Volume Section
            _buildVolumeCard(
              title: '背景音乐',
              value: _backgroundMusicVolume,
              onChanged: (value) {
                setState(() {
                  _backgroundMusicVolume = value;
                });
              },
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

