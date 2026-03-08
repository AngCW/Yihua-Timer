import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VolumeSettingsPage extends StatefulWidget {
  const VolumeSettingsPage({super.key});

  @override
  State<VolumeSettingsPage> createState() => _VolumeSettingsPageState();
}

class _VolumeSettingsPageState extends State<VolumeSettingsPage> {
  double _ringtoneVolume = 0.7;
  double _backgroundMusicVolume = 0.5;
  List<String> _ringtones = ['默认铃声'];

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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement audio test functionality
                  },
                  icon: const Icon(Icons.volume_up, size: 16),
                  label: const Text('音频测试'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B46C1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            
            // Ringtone Settings Section
            _buildRingtoneSettingsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildRingtoneSettingsCard() {
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
              const Text(
                '铃声设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                  letterSpacing: -0.3,
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  _showAddRingtoneDialog(context);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加铃声'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6B46C1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._ringtones.map((ringtone) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRingtoneItem(ringtone),
          )),
        ],
      ),
    );
  }
  
  Widget _buildRingtoneItem(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111827),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.play_arrow, size: 18, color: Color(0xFF6B46C1)),
                onPressed: () {
                  // TODO: Implement play ringtone functionality
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Color(0xFF6B46C1)),
                onPressed: () {
                  _showEditRingtoneDialog(context, name);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
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

