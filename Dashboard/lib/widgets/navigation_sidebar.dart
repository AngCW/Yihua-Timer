import 'package:flutter/material.dart';

class NavigationSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const NavigationSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF6B46C1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: const Text(
              '辩论计时器',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          const Divider(color: Colors.white24, height: 1, thickness: 1),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                  _buildNavItem(
                    icon: Icons.home_rounded,
                    label: '主页',
                    index: 0,
                    isSelected: selectedIndex == 0,
                  ),
                  _buildNavItem(
                    icon: Icons.add_circle_outline_rounded,
                    label: '创建赛事',
                    index: 1,
                    isSelected: selectedIndex == 1,
                  ),
                  _buildNavItem(
                    icon: Icons.bookmark_outline_rounded,
                    label: '已保存赛事',
                    index: 2,
                    isSelected: selectedIndex == 2,
                  ),
                  _buildNavItem(
                    icon: Icons.timer_outlined,
                    label: '计时器',
                    index: 3,
                    isSelected: selectedIndex == 3,
                  ),
                  _buildNavItem(
                    icon: Icons.settings_outlined,
                    label: '设置',
                    index: 4,
                    isSelected: selectedIndex == 4,
                  ),
                ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onItemSelected(index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

