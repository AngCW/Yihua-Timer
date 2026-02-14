import 'package:flutter/material.dart';

class CreateEventSection extends StatelessWidget {
  const CreateEventSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '创建赛事',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _CreateButton(
                label: '默认赛制',
                icon: Icons.add_rounded,
                onPressed: () {
                  // Handle default format creation
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CreateButton(
                label: '自定义赛制',
                icon: Icons.tune_rounded,
                onPressed: () {
                  // Handle custom format creation
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CreateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _CreateButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6B46C1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

