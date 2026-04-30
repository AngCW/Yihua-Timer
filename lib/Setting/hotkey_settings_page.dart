import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'hotkey_binding_model.dart';
import '../main.dart';
import '../database/app_database.dart';

class HotkeySettingsPage extends StatefulWidget {
  const HotkeySettingsPage({super.key});

  @override
  State<HotkeySettingsPage> createState() => _HotkeySettingsPageState();
}

class _HotkeySettingsPageState extends State<HotkeySettingsPage> {
  late HotkeySettings _hotkeySettings;
  String? _editingBindingId;
  final Map<String, FocusNode> _focusNodes = {};

  List<HotkeyProfileData> _profiles = [];
  int? _activeProfileId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _hotkeySettings = HotkeySettings.defaultSettings();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    List<HotkeyProfileData> profiles = await database.select(database.hotkeyProfile).get();
    
    if (profiles.isEmpty) {
      final defaultJson = jsonEncode(HotkeySettings.defaultSettings().toJson());
      final defaultId = await database.into(database.hotkeyProfile).insert(
        HotkeyProfileCompanion.insert(
          profileName: '默认配置',
          hotkeys: defaultJson,
          isDefault: const drift.Value(true),
        )
      );
      profiles = await database.select(database.hotkeyProfile).get();
      await prefs.setInt('active_hotkey_profile_id', defaultId);
      await prefs.setString('hotkey_settings', defaultJson);
    }
    
    int activeId = prefs.getInt('active_hotkey_profile_id') ?? profiles.first.id;
    HotkeyProfileData activeProfile = profiles.firstWhere(
      (p) => p.id == activeId, 
      orElse: () => profiles.first
    );
    
    setState(() {
      _profiles = profiles;
      _activeProfileId = activeProfile.id;
      _hotkeySettings = HotkeySettings.fromJson(jsonDecode(activeProfile.hotkeys));
      _isLoading = false;
    });
    
    await prefs.setString('hotkey_settings', activeProfile.hotkeys);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'hotkey_settings', jsonEncode(_hotkeySettings.toJson()));
  }

  Future<void> _saveToProfile() async {
    if (_activeProfileId == null) return;
    final jsonString = jsonEncode(_hotkeySettings.toJson());
    await (database.update(database.hotkeyProfile)
          ..where((t) => t.id.equals(_activeProfileId!)))
        .write(HotkeyProfileCompanion(hotkeys: drift.Value(jsonString)));
        
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存到当前配置！')));
    final profiles = await database.select(database.hotkeyProfile).get();
    setState(() { _profiles = profiles; });
  }

  Future<void> _switchProfile(int id) async {
    final profile = _profiles.firstWhere((p) => p.id == id);
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt('active_hotkey_profile_id', id);
    await prefs.setString('hotkey_settings', profile.hotkeys);
    
    setState(() {
      _activeProfileId = id;
      _hotkeySettings = HotkeySettings.fromJson(jsonDecode(profile.hotkeys));
    });
  }

  Future<void> _createNewProfile() async {
    String newName = '';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('创建一个新的按键配置'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(labelText: '配置名称'),
            onChanged: (val) => newName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确定'),
            ),
          ],
        );
      }
    );
    
    if (result == true && newName.trim().isNotEmpty) {
      final defaultJson = jsonEncode(HotkeySettings.defaultSettings().toJson());
      final newId = await database.into(database.hotkeyProfile).insert(
        HotkeyProfileCompanion.insert(
          profileName: newName.trim(),
          hotkeys: defaultJson,
          isDefault: const drift.Value(false),
        )
      );
      final profiles = await database.select(database.hotkeyProfile).get();
      setState(() { _profiles = profiles; });
      await _switchProfile(newId);
    }
  }

  bool _hasConflict(HotkeyBinding binding) {
    // ignore: unnecessary_null_comparison
    if (_hotkeySettings == null) return false;
    
    final groups = [
      [_hotkeySettings.previousPage, _hotkeySettings.nextPage, _hotkeySettings.specialPage],
      [_hotkeySettings.pageA1StartStop, _hotkeySettings.pageA1Reset],
      [
        _hotkeySettings.pageA2LeftStartStop, 
        _hotkeySettings.pageA2LeftReset,
        _hotkeySettings.pageA2RightStartStop,
        _hotkeySettings.pageA2RightReset,
        _hotkeySettings.pageA2Swap
      ],
      [
        _hotkeySettings.bgmVolumeUp,
        _hotkeySettings.bgmVolumeDown,
        _hotkeySettings.dingVolumeUp,
        _hotkeySettings.dingVolumeDown
      ],
    ];

    for (var group in groups) {
      if (group.any((b) => b.id == binding.id)) {
        return group.any((b) => b.id != binding.id && b.key == binding.key);
      }
    }
    return false;
  }

  Future<void> _deleteProfile() async {
    if (_activeProfileId == null) return;
    final activeProfile = _profiles.firstWhere((p) => p.id == _activeProfileId);
    if (activeProfile.isDefault) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除配置'),
        content: Text('确定要删除配置 "${activeProfile.profileName}" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('删除')
          ),
        ],
      )
    );

    if (confirm == true) {
      await (database.delete(database.hotkeyProfile)..where((tbl) => tbl.id.equals(activeProfile.id))).go();
      final latestProfiles = await database.select(database.hotkeyProfile).get();
      setState(() { _profiles = latestProfiles; });
      await _switchProfile(latestProfiles.firstWhere((p) => p.isDefault).id);
    }
  }

  Future<void> _exportProfile() async {
    if (_activeProfileId == null) return;
    final activeProfile = _profiles.firstWhere((p) => p.id == _activeProfileId);
    if (activeProfile.isDefault) return;

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: '导出配置',
      fileName: '${activeProfile.profileName}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(activeProfile.hotkeys);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('导出成功！')));
    }
  }

  Future<void> _importProfile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      try {
        final decoded = jsonDecode(content);
        HotkeySettings.fromJson(decoded); 
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无效的配置格式。')));
        return;
      }

      String profileName = result.files.single.name.replaceAll('.json', '');
      
      final newId = await database.into(database.hotkeyProfile).insert(
        HotkeyProfileCompanion.insert(
          profileName: profileName,
          hotkeys: content,
          isDefault: const drift.Value(false),
        )
      );

      final latestProfiles = await database.select(database.hotkeyProfile).get();
      setState(() { _profiles = latestProfiles; });
      await _switchProfile(newId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('导入成功！')));
    }
  }

  Widget _buildProfileSelector() {
    final activeProfile = _profiles.firstWhere(
      (p) => p.id == _activeProfileId, 
      orElse: () => _profiles.first
    );
    
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: activeProfile.isDefault ? null : _saveToProfile,
          icon: const Icon(Icons.save),
          label: const Text('保存到此配置'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
             padding: const EdgeInsets.symmetric(horizontal: 12),
             decoration: BoxDecoration(
               border: Border.all(color: Colors.grey.shade300),
               borderRadius: BorderRadius.circular(8),
               color: Colors.white,
             ),
             child: DropdownButtonHideUnderline(
               child: DropdownButton<int>(
                 value: _activeProfileId,
                 isExpanded: true,
                 items: _profiles.map((p) {
                   return DropdownMenuItem<int>(
                     value: p.id,
                     child: Text(p.profileName + (p.isDefault ? ' (默认配置，不可覆盖)' : '')),
                   );
                 }).toList(),
                 onChanged: (val) {
                   if (val != null) _switchProfile(val);
                 },
               ),
             ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _createNewProfile,
          icon: const Icon(Icons.add),
          label: const Text('新建'),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: _importProfile,
          icon: const Icon(Icons.file_download),
          tooltip: '导入配置',
        ),
        IconButton(
          onPressed: activeProfile.isDefault ? null : _exportProfile,
          icon: const Icon(Icons.file_upload),
          tooltip: '导出配置',
        ),
        IconButton(
          onPressed: activeProfile.isDefault ? null : _deleteProfile,
          icon: const Icon(Icons.delete),
          color: Colors.red,
          tooltip: '删除配置',
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  FocusNode _getFocusNode(String id) {
    if (!_focusNodes.containsKey(id)) {
      _focusNodes[id] = FocusNode();
    }
    return _focusNodes[id]!;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isLoading) ...[
            _buildProfileSelector(),
            const SizedBox(height: 24),
          ],
          // General Controls Section
          _buildSectionCard(
            title: '通用控制',
            children: [
              _buildHotkeyRow(
                binding: _hotkeySettings.previousPage,
                icon: Icons.arrow_back,
              ),
              const Divider(height: 20),
              _buildHotkeyRow(
                binding: _hotkeySettings.nextPage,
                icon: Icons.arrow_forward,
              ),
              const Divider(height: 20),
              _buildHotkeyRow(
                binding: _hotkeySettings.specialPage,
                customText: '可在各自的flow另外调',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Page A1 Section
          _buildSectionCard(
            title: '页面 A1',
            children: [
              _buildHotkeyRow(
                binding: _hotkeySettings.pageA1StartStop,
              ),
              const Divider(height: 20),
              _buildHotkeyRow(
                binding: _hotkeySettings.pageA1Reset,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Page A2 Section
          _buildSectionCard(
            title: '页面 A2',
            children: [
              // Left Timer
              _buildSubSection(
                title: '左边 Timer',
                children: [
                  _buildHotkeyRow(
                    binding: _hotkeySettings.pageA2LeftStartStop,
                  ),
                  const Divider(height: 20),
                  _buildHotkeyRow(
                    binding: _hotkeySettings.pageA2LeftReset,
                  ),
                ],
              ),

              const Divider(height: 24),

              // Right Timer
              _buildSubSection(
                title: '右边 Timer',
                children: [
                  _buildHotkeyRow(
                    binding: _hotkeySettings.pageA2RightStartStop,
                  ),
                  const Divider(height: 20),
                  _buildHotkeyRow(
                    binding: _hotkeySettings.pageA2RightReset,
                  ),
                ],
              ),
              const Divider(height: 24),

              // Swap Timer
              _buildSubSection(
                title: '两端控制',
                children: [
                  _buildHotkeyRow(
                    binding: _hotkeySettings.pageA2Swap,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Audio Controls Section
          _buildSectionCard(
            title: '音量控制',
            children: [
              _buildHotkeyRow(
                binding: _hotkeySettings.bgmVolumeUp,
              ),
              const Divider(height: 20),
              _buildHotkeyRow(
                binding: _hotkeySettings.bgmVolumeDown,
              ),
              const Divider(height: 20),
              _buildHotkeyRow(
                binding: _hotkeySettings.dingVolumeUp,
              ),
              const Divider(height: 20),
              _buildHotkeyRow(
                binding: _hotkeySettings.dingVolumeDown,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSubSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildHotkeyRow({
    required HotkeyBinding binding,
    IconData? icon,
    String? customText,
  }) {
    final isEditing = _editingBindingId == binding.id;
    final hasConflict = _hasConflict(binding);

    return Row(
      children: [
        Expanded(
          child: Text(
            binding.label,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
            if (!_isLoading) {
              final activeProfile = _profiles.firstWhere((p) => p.id == _activeProfileId, orElse: () => _profiles.first);
              if (activeProfile.isDefault) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('默认配置不可编辑，请新建一个配置。')));
                return;
              }
            }
            setState(() {
              _editingBindingId = isEditing ? null : binding.id;
            });
            if (!isEditing) {
              Future.delayed(const Duration(milliseconds: 100), () {
                _getFocusNode(binding.id).requestFocus();
              });
            }
          },
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 80,
              maxWidth: 150,
              minHeight: 40,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isEditing
                  ? const Color(0xFF6B46C1).withOpacity(0.1)
                  : (hasConflict ? Colors.red.withOpacity(0.05) : Colors.grey.shade50),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isEditing ? const Color(0xFF6B46C1) : (hasConflict ? Colors.red : Colors.grey.shade300),
                width: isEditing ? 2 : 1,
              ),
            ),
            child: Focus(
              focusNode: isEditing ? _getFocusNode(binding.id) : null,
              onKeyEvent: (node, event) {
                if (isEditing && event is KeyDownEvent) {
                  final key = _getKeyString(event.logicalKey);
                  if (key != null && key.isNotEmpty) {
                    _updateBinding(binding.id, key);
                    setState(() {
                      _editingBindingId = null;
                    });
                    _getFocusNode(binding.id).unfocus();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: isEditing
                      ? const Text(
                          '按任意键...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B46C1),
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : customText != null
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                customText,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (icon != null) ...[
                                  Icon(
                                    icon,
                                    color: const Color(0xFF374151),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  _getDisplayKey(binding.key),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: hasConflict ? Colors.red : const Color(0xFF374151),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getDisplayKey(String key) {
    if (key == 'ARROW LEFT') return '←';
    if (key == 'ARROW RIGHT') return '→';
    if (key == 'ARROW UP') return '↑';
    if (key == 'ARROW DOWN') return '↓';
    if (key == 'PAGE UP') return 'PgUp';
    if (key == 'PAGE DOWN') return 'PgDn';
    if (key == 'HOME') return 'Home';
    if (key == 'END') return 'End';
    if (key == ' ') return 'SPACE';
    if (key.length == 1) return key.toUpperCase();
    return key;
  }

  String? _getKeyString(LogicalKeyboardKey key) {
    return key.keyLabel.toUpperCase().replaceAll('KEY ', '');
  }

  void _updateBinding(String id, String newKey) {
    setState(() {
      if (id == _hotkeySettings.previousPage.id) {
        _hotkeySettings = _hotkeySettings.copyWith(
          previousPage: _hotkeySettings.previousPage.copyWith(key: newKey),
        );
      } else if (id == _hotkeySettings.nextPage.id) {
        _hotkeySettings = _hotkeySettings.copyWith(
          nextPage: _hotkeySettings.nextPage.copyWith(key: newKey),
        );
      } else if (id == _hotkeySettings.specialPage.id) {
        _hotkeySettings = _hotkeySettings.copyWith(
          specialPage: _hotkeySettings.specialPage.copyWith(key: newKey),
        );
      } else if (id == _hotkeySettings.pageA1StartStop.id) {
        _hotkeySettings = _hotkeySettings.copyWith(
          pageA1StartStop:
              _hotkeySettings.pageA1StartStop.copyWith(key: newKey),
        );
      } else if (id == _hotkeySettings.pageA1Reset.id) {
        _hotkeySettings = _hotkeySettings.copyWith(
          pageA1Reset: _hotkeySettings.pageA1Reset.copyWith(key: newKey),
        );
      } else if (id == _hotkeySettings.pageA2LeftStartStop.id) {
        _hotkeySettings = _hotkeySettings.copyWith(
          pageA2LeftStartStop:
              _hotkeySettings.pageA2LeftStartStop.copyWith(key: newKey),
        );
      } else if (id == _hotkeySettings.pageA2LeftReset.id) {
        _hotkeySettings = _hotkeySettings.copyWith(
          pageA2LeftReset:
              _hotkeySettings.pageA2LeftReset.copyWith(key: newKey),
        );
      } else if (id == _hotkeySettings.pageA2RightStartStop.id) {
        _hotkeySettings = _hotkeySettings.copyWith(
          pageA2RightStartStop:
              _hotkeySettings.pageA2RightStartStop.copyWith(key: newKey),
        );
      } else if (id == _hotkeySettings.pageA2RightReset.id) {
        _hotkeySettings = _hotkeySettings.copyWith(
          pageA2RightReset:
              _hotkeySettings.pageA2RightReset.copyWith(key: newKey),
        );
      } else if (id == _hotkeySettings.pageA2Swap.id) {
        _hotkeySettings = _hotkeySettings.copyWith(
          pageA2Swap: _hotkeySettings.pageA2Swap.copyWith(key: newKey),
        );
      } else if (id == _hotkeySettings.bgmVolumeUp.id) {
        _hotkeySettings = _hotkeySettings.copyWith(
          bgmVolumeUp: _hotkeySettings.bgmVolumeUp.copyWith(key: newKey),
        );
      } else if (id == _hotkeySettings.bgmVolumeDown.id) {
        _hotkeySettings = _hotkeySettings.copyWith(
          bgmVolumeDown: _hotkeySettings.bgmVolumeDown.copyWith(key: newKey),
        );
      } else if (id == _hotkeySettings.dingVolumeUp.id) {
        _hotkeySettings = _hotkeySettings.copyWith(
          dingVolumeUp: _hotkeySettings.dingVolumeUp.copyWith(key: newKey),
        );
      } else if (id == _hotkeySettings.dingVolumeDown.id) {
        _hotkeySettings = _hotkeySettings.copyWith(
          dingVolumeDown: _hotkeySettings.dingVolumeDown.copyWith(key: newKey),
        );
      }
    });

    _saveSettings();
  }
}
