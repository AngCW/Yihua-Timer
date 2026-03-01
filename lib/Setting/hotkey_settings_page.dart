import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hotkey_binding_model.dart';

class HotkeySettingsPage extends StatefulWidget {
  const HotkeySettingsPage({super.key});

  @override
  State<HotkeySettingsPage> createState() => _HotkeySettingsPageState();
}

class _HotkeySettingsPageState extends State<HotkeySettingsPage> {
  late HotkeySettings _hotkeySettings;
  String? _editingBindingId;
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _hotkeySettings = HotkeySettings.defaultSettings();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('hotkey_settings');
    if (jsonString != null) {
      setState(() {
        _hotkeySettings = HotkeySettings.fromJson(jsonDecode(jsonString));
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'hotkey_settings', jsonEncode(_hotkeySettings.toJson()));
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
          // General Controls Section
          _buildSectionCard(
            title: '通用控制',
            children: [
              _buildHotkeyRow(
                binding: _hotkeySettings.previousPage,
                icon: Icons.arrow_back,
              ),
              const Divider(height: 32),
              _buildHotkeyRow(
                binding: _hotkeySettings.nextPage,
                icon: Icons.arrow_forward,
              ),
              const Divider(height: 32),
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
              const Divider(height: 32),
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
                  const Divider(height: 32),
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
                  const Divider(height: 32),
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
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
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
            width: 80,
            height: 40,
            decoration: BoxDecoration(
              color: isEditing
                  ? const Color(0xFF6B46C1).withOpacity(0.1)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isEditing ? const Color(0xFF6B46C1) : Colors.grey.shade300,
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
                        : icon != null
                            ? Icon(
                                icon,
                                color: const Color(0xFF374151),
                                size: 20,
                              )
                            : Text(
                                binding.key,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF374151),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? _getKeyString(LogicalKeyboardKey key) {
    // Map common keys to their display strings
    if (key == LogicalKeyboardKey.arrowLeft) return '←';
    if (key == LogicalKeyboardKey.arrowRight) return '→';
    if (key == LogicalKeyboardKey.arrowUp) return '↑';
    if (key == LogicalKeyboardKey.arrowDown) return '↓';

    // Get the key label, removing "Key" prefix
    final keyLabel = key.keyLabel;
    if (keyLabel.length == 1) {
      return keyLabel.toUpperCase();
    }

    // Handle special keys
    if (keyLabel.startsWith('Key')) {
      return keyLabel.substring(3);
    }

    return keyLabel.length <= 2 ? keyLabel.toUpperCase() : null;
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
      }
    });

    _saveSettings();
  }
}
