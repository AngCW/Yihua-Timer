import 'dart:io';
import 'package:flutter/material.dart';
import '../screens/changelog_page.dart';

class NavigationSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const NavigationSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  void _openChangelog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ChangelogPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // App title
          Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: const Text(
              'YiHuaTimer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const Divider(color: Colors.white24, height: 1, thickness: 1),

          // Navigation Items + bottom section
          Expanded(
            child: Column(
              children: [
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

                const Divider(color: Colors.white24, height: 1, thickness: 1),

                // ── Version + Changelog section ──────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Changelog button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => _openChangelog(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            alignment: Alignment.centerLeft,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.history_rounded, size: 17),
                          label: const Text(
                            '更新日志',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      // Version badge
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Text(
                                'v1.7.0',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '当前版本',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Exit button ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => exit(0),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                      label: const Text(
                        '退出应用',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
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
