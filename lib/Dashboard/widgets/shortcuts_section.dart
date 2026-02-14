import 'package:flutter/material.dart';
import '../../Setting/hotkey_binding_model.dart';

class ShortcutsSection extends StatelessWidget {
  const ShortcutsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final hotkeySettings = HotkeySettings.defaultSettings();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快捷键',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
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
              // General Controls Section
              _buildSectionTitle('通用控制'),
              const SizedBox(height: 16),
              _buildHotkeyRow(
                binding: hotkeySettings.previousPage,
                icon: Icons.arrow_back,
              ),
              const Divider(height: 24),
              _buildHotkeyRow(
                binding: hotkeySettings.nextPage,
                icon: Icons.arrow_forward,
              ),
              const Divider(height: 24),
              _buildHotkeyRow(
                binding: hotkeySettings.specialPage,
                customText: '可在各自的flow另外调',
              ),
              
              const SizedBox(height: 32),
              
              // Page A1 Section
              _buildSectionTitle('页面 A1'),
              const SizedBox(height: 16),
              _buildHotkeyRow(
                binding: hotkeySettings.pageA1StartStop,
              ),
              const Divider(height: 24),
              _buildHotkeyRow(
                binding: hotkeySettings.pageA1Reset,
              ),
              
              const SizedBox(height: 32),
              
              // Page A2 Section
              _buildSectionTitle('页面 A2'),
              const SizedBox(height: 16),
              // Left Timer
              _buildSubSectionTitle('左边 Timer'),
              const SizedBox(height: 12),
              _buildHotkeyRow(
                binding: hotkeySettings.pageA2LeftStartStop,
              ),
              const Divider(height: 24),
              _buildHotkeyRow(
                binding: hotkeySettings.pageA2LeftReset,
              ),
              
              const SizedBox(height: 24),
              
              // Right Timer
              _buildSubSectionTitle('右边 Timer'),
              const SizedBox(height: 12),
              _buildHotkeyRow(
                binding: hotkeySettings.pageA2RightStartStop,
              ),
              const Divider(height: 24),
              _buildHotkeyRow(
                binding: hotkeySettings.pageA2RightReset,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildSubSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildHotkeyRow({
    required HotkeyBinding binding,
    IconData? icon,
    String? customText,
  }) {
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
        Container(
          width: 80,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Center(
            child: customText != null
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
      ],
    );
  }
}
