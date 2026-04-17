import 'package:flutter/material.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

class ChangelogEntry {
  final String version;
  final String date;
  final List<String> changes;
  final List<String> changesEn;

  ChangelogEntry({
    required this.version,
    required this.date,
    required this.changes,
    required this.changesEn,
  });
}

// ─── Static Data ──────────────────────────────────────────────────────────────

final List<ChangelogEntry> _changelogData = [
  ChangelogEntry(
    version: 'v1.7.0',
    date: '2026-04-17',
    changes: [
      '（希望）修复了即使已设置继承计时器，页面有时也无法正确继承的问题',
      '修复了复制赛程或赛程文件夹时，未能正确保留页面继承计时器关联的问题',
      '添加了版本数据库控制机制，现各版本的数据库和资源将完全分离互不干扰',
    ],
    changesEn: [
      'Hopefully fixed the issue where pages do not inherit the timers of other pages even when they should have',
      'Fixed the issue where copying a flow or flow folder does not copy the inherited page timer values',
      'Added version database control; now databases and asset directories are cleanly isolated by version',
    ],
  ),
  ChangelogEntry(
    version: 'v1.6.0',
    date: '2026-04-05',
    changes: [
      '在应用名称中加入了版本号',
      '修复了（希望啦）实际计时器界面中，因为屏幕尺寸不同导致计时器与环节名称位置发生偏移的问题',
      '允许用户在预览页面中编辑屏幕尺寸，以便在不同尺寸下查看页面',
      '在页面编辑器中新增了上一页和下一页按钮',
      '移除了用户修改默认快捷键页面中部分属性的权限',
      '当同一快捷键区域内存在相同的快捷键时，增加了高亮提醒',
      '修复了导入带有继承计时器的页面时，无法正确保存其所继承页面的问题',
      '修复了无法从赛事中删除学校的问题',
      '添加了清除本地存储中旧数据的选项，确保设备中无数据残留',
      '修复了当一个计时器归零时，启动一个计时器并停止另一个计时器的快捷键失效的问题',
      '修复了快捷键配置无法导入到新应用实例的问题',
      '新增了快捷键配置文件机制，使用户更容易理解和管理快捷键设置',
      '修复了窗口大小调整与初始显示状态的问题',
    ],
    changesEn: [
      'changed application name to have the version numbering as well',
      'fixed(hopefully) issue where positions of timers and section names in the actual timer would change in different screen sizes',
      'allow users to edit screen sizes in preview pages to view the page in different sizes',
      'added next and previous page buttons in the page editor',
      'remove permissions for users to change some values of the default shortcut pages',
      'added highlighting to hotkeys if they are the same key in the same hotkey section',
      'fixed issue where imported pages with inherited timers would not save the page that they inherited',
      'Fixed issue where schools could not be deleted from events',
      'added option to remove old data in local storages to ensure no leftover data is in the device',
      'fixed issue with start one timer stop the other hotkey which would not work when one timer reaches zero',
      'fixed issue where hotkeys would not be imported into a new app instance',
      'added hotkey profiing for easier understanding of hotkey settings',
      'fixed window resizing issues',
    ],
  ),
  ChangelogEntry(
    version: 'v1.5.0',
    date: '2026-03-26',
    changes: [
      '添加“在线检查更新”功能，支持从云端获取最新版本信息',
      '修复了计时器详情页无法显示子文件夹的 Bug，现在支持无限级文件夹导航',
      '优化了分享导入逻辑：导入新版本数据时会自动清理旧数据，确保资源（图片、字体）同步完整',
      '在通用设置中增加了“完全清除所有数据”按钮，支持一键重置应用',
    ],
    changesEn: [
      'Added "Online Update Check" feature to stay up-to-date with the latest versions',
      'Fixed a bug where subfolders were not displayed in the Timer details page',
      'Optimized shared data import: automatically cleans old data to ensure perfect asset synchronization',
      'Added "Clear All Data" button in General Settings for a fresh start',
    ],
  ),
  ChangelogEntry(
    version: 'v1.04',
    date: '2026-03-24',
    changes: [
      '修复了文件夹删除不完全导致“孤儿”赛程残留在数据库中的问题',
      '优化了文件夹删除逻辑，现在支持彻底递归删除所有子文件夹及其关联的所有数据',
      '修复了计时器选择界面（可用赛程）会显示已删除文件夹的问题，现在仅显示存在的顶层文件夹',
    ],
    changesEn: [
      'Fixed an issue where partial folder deletion left orphaned flows and timers in the database',
      'Implemented full recursive folder deletion to ensure all subfolders and their data are completely removed',
      'Fixed UI bug in the timer selection screen where deleted folders were still visible',
    ],
  ),
  ChangelogEntry(
    version: 'v1.03',
    date: '2026-03-23',
    changes: [
      '添加"分享软件"功能：可在通用设置中将应用打包为 ZIP 文件并保存至下载文件夹',
      '支持"仅分享软件"与"分享软件+数据"两种模式',
      '"软件+数据"模式会导出当前快捷键配置与全部赛事数据',
      '分享后的 ZIP 解压运行时，将自动导入配置与数据，无需手动设置',
      '更新应用图标为官方 LOGO',
    ],
    changesEn: [
      'Added "Share App" feature: package the app as a ZIP from General Settings and save to Downloads folder',
      'Supports two modes: "Software Only" and "Software + Data"',
      '"Software + Data" mode exports current hotkey settings and all event data',
      'When extracted and launched, the shared ZIP auto-imports all config and data with no setup required',
      'Updated application icon to official LOGO',
    ],
  ),
  ChangelogEntry(
    version: 'v1.02',
    date: '2026-03-20',
    changes: [
      '修复了重复导入导出赛事导致的日期溢出错误 (RangeError)',
      '修复了导入具有重复背景音乐/提示音的赛事时引发的崩溃问题 (Too many elements)',
      '修复了保存导出赛事时，如果未手动保留后缀则不会自动补全为 .zip 的问题',
      '修复了主页中的快捷键仅显示方向图标而不显示英文字母的 UI 问题',
      '现在主页的快捷键显示会与设置页面的自定义快捷键完全同步渲染',
      '更改了通用快捷键的默认值（上一页为 B，下一页为 N）',
      '增加了 MSIX 安装包打包支持',
    ],
    changesEn: [
      'Fixed a date overflow error (RangeError) caused by recursive event export/import',
      'Fixed application crash (Too many elements) when importing events with duplicate audio names',
      'Fixed an issue where exporting an event without appending .zip would result in an extensionless file',
      'Dashboard shortcut display now automatically syncs with customized user settings',
      'Changed default general hotkeys (Previous Page to B, Next Page to N)',
      'Added support for MSIX installer packaging',
    ],
  ),
  ChangelogEntry(
    version: 'v1.01',
    date: '2026-03-16',
    changes: [
      '添加页面拖拽排序功能',
      '添加文件夹嵌套功能（最多5层）',
      '修复导入赛事时开始与结束日期丢失的问题',
      '添加计时页面滚动锁定，防止键盘/触摸板意外翻页',
      '添加中文输入法提醒',
      '添加计时器互斥逻辑（启动一个计时器自动停止另一个）',
      '将应用程序名称更名为 YiHuaTimer',
      '在仪表盘“近期赛事”中显示文件夹内的流程',
      '添加模板删除保护（检查模板是否被其他赛事使用）',
      '重构音量控制系统：支持背景音乐（BGM）与提示音独立控制与测试',
      '添加计时页面音量控制快捷键（PageUp/PageDown 用于 BGM，Home/End 用于提示音）',
    ],
    changesEn: [
      'Added drag-and-drop page reordering functionality',
      'Added folder nesting support (up to 5 levels)',
      'Fixed issue where start/end dates were lost during event import',
      'Added scroll lock to timer pages to prevent accidental page turns',
      'Added reminder notice for Chinese input method',
      'Implemented timer mutual exclusion (starting one stops the other)',
      'Renamed application to YiHuaTimer',
      'Display flows inside folders in the Dashboard "Latest Flows" section',
      'Added template deletion safeguard (prevents deletion if used by events)',
      'Revamped volume control system with independent BGM and Ding testing',
      'Added in-timer volume hotkeys (PageUp/PageDown for BGM, Home/End for Ding)',
    ],
  ),
  ChangelogEntry(
    version: 'v1.00',
    date: '2026-03-10',
    changes: ['应用程序发布'],
    changesEn: ['Application released'],
  ),
];

// ─── Widget ───────────────────────────────────────────────────────────────────

class ChangelogPage extends StatelessWidget {
  const ChangelogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: const Color(0xFF312E81),
            foregroundColor: Colors.white,
            title: const Text('更新日志 (Changelog)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ],
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: _changelogData.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final entry = _changelogData[i];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: i == 0
                        ? const Color(0xFF6B46C1).withOpacity(0.4)
                        : Colors.grey.shade200,
                    width: i == 0 ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: i == 0
                            ? const Color(0xFF6B46C1).withOpacity(0.07)
                            : Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(11),
                          topRight: Radius.circular(11),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (i == 0)
                            Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B46C1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '最新 (Latest)',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          Text(
                            entry.version,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: i == 0
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            entry.date,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    // Change list boxes
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Column(
                        children: [
                          // Chinese Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.blue.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('中文更新',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                        fontSize: 12)),
                                const SizedBox(height: 8),
                                ...entry.changes
                                    .map((c) => _buildChangeItem(c, i == 0)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // English Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.indigo.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('English Changelog',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                        fontSize: 12)),
                                const SizedBox(height: 8),
                                ...entry.changesEn
                                    .map((c) => _buildChangeItem(c, i == 0)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChangeItem(String text, bool isLatest) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 14,
              color: isLatest ? const Color(0xFF6B46C1) : Colors.grey.shade400),
          const SizedBox(width: 8),
          Expanded(
            child:
                Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
