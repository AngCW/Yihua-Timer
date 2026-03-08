import 'package:flutter/material.dart';
import 'hotkey_settings_page.dart';
import 'volume_settings_page.dart';
import 'general_settings_page.dart';
import 'timer_template_settings_page.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onBack;

  const SettingsPage({super.key, this.onBack});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '设置',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    label: '通用设置',
                    index: 0,
                    isSelected: _selectedTabIndex == 0,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    label: '快捷键设置',
                    index: 1,
                    isSelected: _selectedTabIndex == 1,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    label: '音频设置',
                    index: 2,
                    isSelected: _selectedTabIndex == 2,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    label: '铃声设计',
                    index: 3,
                    isSelected: _selectedTabIndex == 3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Content
          Expanded(
            child: () {
              switch (_selectedTabIndex) {
                case 0:
                  return const GeneralSettingsPage();
                case 1:
                  return const HotkeySettingsPage();
                case 2:
                  return const VolumeSettingsPage();
                case 3:
                default:
                  return const TimerTemplateSettingsPage();
              }
            }(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B46C1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}
