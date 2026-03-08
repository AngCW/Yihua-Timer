import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../database/app_database.dart';
import '../main.dart';
import 'page_manager_page.dart';

class FlowManagerPage extends StatefulWidget {
  final EventData event;
  final FlowData? initialFlow;

  const FlowManagerPage({super.key, required this.event, this.initialFlow});

  @override
  State<FlowManagerPage> createState() => _FlowManagerPageState();
}

class _FlowManagerPageState extends State<FlowManagerPage> {
  final _flowNameController = TextEditingController();
  FlowData? _currentFlow;
  String? _fontFile;
  String? _frontpageFile;
  String? _backgroundFile;
  String? _imagesDirPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlow();
  }

  Future<void> _loadFlow() async {
    final supportDir = await getApplicationSupportDirectory();
    _imagesDirPath = p.join(
        supportDir.path, 'YiHuaTimer', 'images', widget.event.id.toString());

    if (widget.initialFlow != null) {
      _currentFlow = widget.initialFlow;
      _flowNameController.text = _currentFlow!.flowName ?? '';
      _updateFileExistence();
      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateFileExistence() async {
    final font = await _getFlowFontPath();
    final front = await _getFlowImagePath('frontpage');
    final back = await _getFlowImagePath('background');
    if (mounted) {
      setState(() {
        _fontFile = font;
        _frontpageFile = front;
        _backgroundFile = back;
      });
    }
  }

  Future<String?> _getFlowFontPath() async {
    if (_currentFlow?.fontName == null) return null;
    try {
      final supportDir = await getApplicationSupportDirectory();
      final filePath = p.join(supportDir.path, 'YiHuaTimer', 'images',
          widget.event.id.toString(), _currentFlow!.fontName!);
      if (await File(filePath).exists()) {
        return _currentFlow!.fontName;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getFlowImagePath(String type) async {
    final fileName = type == 'frontpage'
        ? _currentFlow?.frontpageName
        : _currentFlow?.backgroundName;

    if (fileName == null) return null;

    try {
      final supportDir = await getApplicationSupportDirectory();
      final filePath = p.join(supportDir.path, 'YiHuaTimer', 'images',
          widget.event.id.toString(), fileName);
      if (await File(filePath).exists()) {
        return fileName;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickAndSaveFile(String type) async {
    if (_currentFlow == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先保存赛程')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: type == 'font' ? FileType.any : FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      final originalPath = result.files.single.path!;
      final extension = p.extension(result.files.single.name);
      final fileName = '$type$extension';

      try {
        final supportDir = await getApplicationSupportDirectory();
        final imagesDir = Directory(p.join(supportDir.path, 'YiHuaTimer',
            'images', widget.event.id.toString()));

        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }

        // Handle Flow level assets
        String? oldFileName;
        if (type == 'font') {
          oldFileName = _currentFlow!.fontName;
        } else if (type == 'frontpage') {
          oldFileName = _currentFlow!.frontpageName;
        } else if (type == 'background') {
          oldFileName = _currentFlow!.backgroundName;
        }

        if (oldFileName != null) {
          final oldFilePath = p.join(imagesDir.path, oldFileName);
          final oldFile = File(oldFilePath);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        }

        final companion = FlowCompanion(
          fontName: type == 'font'
              ? drift.Value(fileName)
              : const drift.Value.absent(),
          frontpageName: type == 'frontpage'
              ? drift.Value(fileName)
              : const drift.Value.absent(),
          backgroundName: type == 'background'
              ? drift.Value(fileName)
              : const drift.Value.absent(),
        );

        await (database.update(database.flow)
              ..where((t) => t.id.equals(_currentFlow!.id)))
            .write(companion);

        final updatedFlow = await (database.select(database.flow)
              ..where((t) => t.id.equals(_currentFlow!.id)))
            .getSingle();
        _currentFlow = updatedFlow;

        final targetPath = p.join(imagesDir.path, fileName);
        await File(originalPath).copy(targetPath);
        await _updateFileExistence();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_getAssetLabel(type)}已更新: $fileName')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('同步失败: $e')),
          );
        }
      }
    }
  }

  String _getAssetLabel(String type) {
    switch (type) {
      case 'font':
        return '字体';
      case 'frontpage':
        return '封面';
      case 'background':
        return '背景';
      default:
        return '素材';
    }
  }

  Future<void> _addPage() async {
    if (_currentFlow == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先创建赛程')),
      );
      return;
    }

    try {
      final pages = await (database.select(database.page)
            ..where((t) => t.flowId.equals(_currentFlow!.id)))
          .get();

      final newPage = await database.into(database.page).insertReturning(
            PageCompanion.insert(
              pageName: drift.Value('第${pages.length + 1}页'),
              flowId: drift.Value(_currentFlow!.id),
              pagePosition: drift.Value(pages.length + 1),
            ),
          );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PageManagerPage(
              event: widget.event,
              flow: _currentFlow!,
              page: newPage,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _flowNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('${widget.event.eventName} - 赛程管理'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flow Info Section
            _buildSectionTitle('赛程设置 (Flow Settings)'),
            const SizedBox(height: 16),
            _buildSchoolSelectionSection(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _flowNameController,
                    decoration: InputDecoration(
                      hintText: '例如: 初赛第一场',
                      labelText: '赛程名称 (Flow Name)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _saveFlowName,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: const Text('保存赛程'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildUploadBox(
                    label: '全局字体 (Flow Font)',
                    icon: Icons.font_download_rounded,
                    onTap: () => _pickAndSaveFile('font'),
                    currentFile: _fontFile),
                _buildUploadBox(
                    label: '全局封面 (Flow Frontpage)',
                    icon: Icons.image_rounded,
                    onTap: () => _pickAndSaveFile('frontpage'),
                    currentFile: _frontpageFile),
                _buildUploadBox(
                    label: '全局背景 (Flow Background)',
                    icon: Icons.wallpaper_rounded,
                    onTap: () => _pickAndSaveFile('background'),
                    currentFile: _backgroundFile),
              ],
            ),

            const SizedBox(height: 40),

            // ── Default Pages Box ─────────────────────────────────────────
            _buildSectionTitle('快捷跳转页面 (Default Shortcut Pages)'),
            const SizedBox(height: 8),
            Text(
              '这些页面在每个赛程创建时自动生成，支持独立快捷键，供应急切换使用。',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF4FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF6B46C1).withOpacity(0.3), width: 2),
              ),
              child: _currentFlow == null
                  ? const Center(child: Text('请先创建赛程'))
                  : StreamBuilder<List<PageData>>(
                      stream: (database.select(database.page)
                            ..where((t) => t.flowId.equals(_currentFlow!.id))
                            ..where((t) => t.isDefaultPage.equals(true))
                            ..orderBy([
                              (t) =>
                                  drift.OrderingTerm(expression: t.pagePosition)
                            ]))
                          .watch(),
                      builder: (context, snapshot) {
                        final pages = snapshot.data ?? [];
                        if (pages.isEmpty) {
                          return const Text(
                            '暂无默认页面（重新创建赛程将自动生成）',
                            style: TextStyle(color: Colors.grey),
                          );
                        }
                        return SizedBox(
                          height: 130,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: pages
                                .map((pg) => Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: _buildDefaultPageBox(context, pg),
                                    ))
                                .toList(),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 40),

            // ── Main Pages Box ────────────────────────────────────────────
            _buildSectionTitle('页面管理 (Page Management)'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
              child: _currentFlow == null
                  ? const Center(child: Text('请先创建赛程以管理页面'))
                  : StreamBuilder<List<PageData>>(
                      stream: (database.select(database.page)
                            ..where((t) => t.flowId.equals(_currentFlow!.id))
                            ..where((t) => t.isDefaultPage.equals(false))
                            ..orderBy([
                              (t) =>
                                  drift.OrderingTerm(expression: t.pagePosition)
                            ]))
                          .watch(),
                      builder: (context, snapshot) {
                        final pages = snapshot.data ?? [];
                        return Column(
                          children: [
                            SizedBox(
                              height: 130, // Enough for 80x80 box + text
                              child: ReorderableListView(
                                scrollDirection: Axis.horizontal,
                                onReorder: (oldIndex, newIndex) {
                                  _reorderPages(pages, oldIndex, newIndex);
                                },
                                children: [
                                  ...pages.map((p) =>
                                      ReorderableDelayedDragStartListener(
                                        key: ValueKey(p.id),
                                        index: pages.indexOf(p),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 16.0),
                                          child: _buildPageBox(context, p),
                                        ),
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _buildAddPageButton(context),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reorderPages(
      List<PageData> pages, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = pages.removeAt(oldIndex);
    pages.insert(newIndex, item);

    for (int i = 0; i < pages.length; i++) {
      await (database.update(database.page)
            ..where((t) => t.id.equals(pages[i].id)))
          .write(PageCompanion(pagePosition: drift.Value(i + 1)));
    }
  }

  Future<void> _saveFlowName() async {
    if (_flowNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入赛程名称')),
      );
      return;
    }

    try {
      if (_currentFlow == null) {
        final flows = await (database.select(database.flow)
              ..where((t) => t.eventId.equals(widget.event.id)))
            .get();

        final newFlow = await database.into(database.flow).insertReturning(
              FlowCompanion.insert(
                flowName: drift.Value(_flowNameController.text),
                eventId: drift.Value(widget.event.id),
                flowPosition: drift.Value(flows.length + 1),
              ),
            );
        setState(() {
          _currentFlow = newFlow;
        });
        // Create 5 default pages for every new flow
        await _createDefaultPages(newFlow.id);
      } else {
        await (database.update(database.flow)
              ..where((t) => t.id.equals(_currentFlow!.id)))
            .write(FlowCompanion(
          flowName: drift.Value(_flowNameController.text),
        ));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('赛程信息已保存')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  /// Insert the 5 mandatory default pages for a brand-new flow.
  Future<void> _createDefaultPages(int flowId) async {
    // Find the first available timer template (may be null)
    final templates = await database.select(database.timerTemplate).get();
    final firstTemplateId = templates.isNotEmpty ? templates.first.id : null;

    // Helper to insert a page and optionally a timer
    Future<void> insertPage({
      required String name,
      required String pageType,
      required int position,
      bool useFrontpage = false,
      String? sectionName,
      bool withTimer = false,
      bool isDefault = true,
      String? hotkey,
    }) async {
      final pg = await database.into(database.page).insertReturning(
            PageCompanion.insert(
              pageName: drift.Value(name),
              flowId: drift.Value(flowId),
              pagePosition: drift.Value(position),
              pageTypeId: drift.Value(pageType),
              useFrontpage: drift.Value(useFrontpage),
              sectionName: drift.Value(sectionName),
              isDefaultPage: drift.Value(isDefault),
              hotkeyValue: drift.Value(hotkey),
            ),
          );

      if (withTimer && firstTemplateId != null) {
        await database.into(database.timer).insert(
              TimerCompanion.insert(
                pageId: drift.Value(pg.id),
                timerTemplateId: drift.Value(firstTemplateId),
                timerType: const drift.Value('single'),
                startTime: const drift.Value('2:0'), // 2 minutes
              ),
            );
      }
    }

    await insertPage(
      name: '主页',
      pageType: 'C',
      position: 1,
      useFrontpage: true,
      isDefault: false, // 主页 belongs to the main flow box
    );
    await insertPage(
      name: '断线缓冲计时环节',
      pageType: 'A1',
      position: 2,
      sectionName: '断线缓冲计时环节',
      withTimer: true,
      hotkey: '1',
    );
    await insertPage(
      name: '断线缓冲标题页面',
      pageType: 'B',
      position: 3,
      sectionName: '断线缓冲标题页面',
      hotkey: '2',
    );
    await insertPage(
      name: '立场捍卫环节',
      pageType: 'A1',
      position: 4,
      sectionName: '立场捍卫环节',
      withTimer: true,
      hotkey: '3',
    );
    await insertPage(
      name: '资料检证环节',
      pageType: 'A1',
      position: 5,
      sectionName: '资料检证环节',
      withTimer: true,
      hotkey: '4',
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildUploadBox({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    String? currentFile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 140,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: currentFile != null
                    ? const Color(0xFF6B46C1)
                    : Colors.grey.shade200,
                width: currentFile != null ? 2 : 1,
              ),
              boxShadow: [
                if (currentFile != null)
                  BoxShadow(
                    color: const Color(0xFF6B46C1).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  currentFile != null ? Icons.check_circle_rounded : icon,
                  size: 32,
                  color: currentFile != null
                      ? const Color(0xFF059669)
                      : Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    currentFile ?? '点击上传',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: currentFile != null
                          ? const Color(0xFF059669)
                          : Colors.grey.shade500,
                      fontWeight: currentFile != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Default-page tile: purple border, keyboard shortcut badge, navigates to PageManagerPage.
  Widget _buildDefaultPageBox(BuildContext context, PageData page) {
    final hotkey =
        (page.hotkeyValue ?? '').isNotEmpty ? page.hotkeyValue! : null;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PageManagerPage(
              event: widget.event,
              flow: _currentFlow!,
              page: page,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6B46C1),
                    width: 2,
                  ),
                ),
                child: _buildMiniPreview(page),
              ),
              if (hotkey != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B46C1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      hotkey,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            child: Text(
              page.pageName ?? '未命名',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B46C1),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageBox(BuildContext context, PageData page) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showPageContextMenu(context, page, details.globalPosition);
      },
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PageManagerPage(
                event: widget.event,
                flow: _currentFlow!,
                page: page,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: _buildMiniPreview(page),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 80,
              child: Text(
                page.pageName ?? '未命名',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPageContextMenu(
      BuildContext context, PageData page, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.delete_rounded, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('删除页面', style: TextStyle(color: Colors.red)),
            ],
          ),
          onTap: () => _deletePage(page),
        ),
      ],
    );
  }

  Future<void> _deletePage(PageData page) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('确认删除'),
              content: Text('确认要删除页面 "${page.pageName}" 吗？'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child:
                        const Text('删除', style: TextStyle(color: Colors.red))),
              ],
            ));

    if (confirmed == true) {
      try {
        final allPages = await (database.select(database.page)
              ..where((t) => t.flowId.equals(_currentFlow!.id))
              ..orderBy(
                  [(t) => drift.OrderingTerm(expression: t.pagePosition)]))
            .get();

        await (database.delete(database.timer)
              ..where((t) => t.pageId.equals(page.id)))
            .go();
        await (database.delete(database.images)
              ..where((t) => t.pageId.equals(page.id)))
            .go();

        await (database.delete(database.page)
              ..where((t) => t.id.equals(page.id)))
            .go();

        // Renumber
        int pos = 1;
        for (final p in allPages) {
          if (p.id == page.id) continue;
          await (database.update(database.page)
                ..where((t) => t.id.equals(p.id)))
              .write(PageCompanion(pagePosition: drift.Value(pos++)));
        }

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('页面已删除')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('删除失败: $e')));
        }
      }
    }
  }

  Widget _buildMiniPreview(PageData page) {
    if (_imagesDirPath == null || _currentFlow == null) {
      return const Icon(Icons.description_rounded,
          size: 32, color: Color(0xFF6B46C1));
    }

    final imageName =
        (page.useFrontpage == true && _currentFlow!.frontpageName != null)
            ? _currentFlow!.frontpageName
            : _currentFlow!.backgroundName;

    if (imageName == null) {
      return const Icon(Icons.description_rounded,
          size: 32, color: Color(0xFF6B46C1));
    }

    final imagePath = p.join(_imagesDirPath!, imageName);
    final file = File(imagePath);

    if (!file.existsSync()) {
      return const Icon(Icons.description_rounded,
          size: 32, color: Color(0xFF6B46C1));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(file, fit: BoxFit.cover),
          Container(color: Colors.black12),
          Center(
            child: Icon(
              page.pageTypeId == 'C'
                  ? Icons.image_outlined
                  : Icons.timer_outlined,
              size: 24,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPageButton(BuildContext context) {
    return InkWell(
      onTap: _addPage,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF6B46C1).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6B46C1).withOpacity(0.2),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 32,
              color: Color(0xFF6B46C1),
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 80,
            child: Text(
              '添加页面',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolSelectionSection() {
    if (_currentFlow == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '参赛学校 (Participating Schools)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<SchoolData>>(
          stream: (database.select(database.school)
                ..where((t) => t.eventId.equals(widget.event.id)))
              .watch(),
          builder: (context, snapshot) {
            final schools = snapshot.data ?? [];
            return Row(
              children: [
                Expanded(
                  child: _buildSchoolDropdown(
                    label: '正方学校 (School A)',
                    value: _currentFlow?.schoolAId,
                    schools: schools,
                    onChanged: (val) => _updateFlowSchool(val, isA: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSchoolDropdown(
                    label: '反方学校 (School B)',
                    value: _currentFlow?.schoolBId,
                    schools: schools,
                    onChanged: (val) => _updateFlowSchool(val, isA: false),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton.filled(
                  onPressed: _showAddSchoolDialog,
                  style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF6B46C1)),
                  icon: const Icon(Icons.add_rounded),
                  tooltip: '添加新学校',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSchoolDropdown({
    required String label,
    required int? value,
    required List<SchoolData> schools,
    required ValueChanged<int?> onChanged,
  }) {
    // Determine if the current value is actually present in the schools list.
    // This prevents the assertion error when the stream is loading or out of sync.
    final bool valueExists = schools.any((s) => s.id == value);
    final int? effectiveValue = valueExists ? value : null;

    return DropdownButtonFormField<int>(
      value: effectiveValue,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: Text('未选择'),
        ),
        ...schools.map((s) => DropdownMenuItem<int>(
              value: s.id,
              child: Row(
                children: [
                  _buildSchoolLogoSmall(s),
                  const SizedBox(width: 8),
                  Text(s.schoolName),
                ],
              ),
            )),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildSchoolLogoSmall(SchoolData school) {
    return FutureBuilder<ImagesData?>(
      future: school.logoImageId != null
          ? (database.select(database.images)
                ..where((t) => t.id.equals(school.logoImageId!)))
              .getSingleOrNull()
          : Future.value(null),
      builder: (context, snapshot) {
        final img = snapshot.data;
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: img != null
              ? FutureBuilder<Directory>(
                  future: getApplicationSupportDirectory(),
                  builder: (context, dirSnap) {
                    if (!dirSnap.hasData) return const SizedBox.shrink();
                    final path = p.join(dirSnap.data!.path, 'YiHuaTimer',
                        'schools', widget.event.id.toString(), img.imageName!);
                    if (!File(path).existsSync()) {
                      return const Icon(Icons.school, size: 14);
                    }
                    return ClipOval(
                        child: Image.file(File(path), fit: BoxFit.cover));
                  },
                )
              : const Icon(Icons.school, size: 14, color: Colors.grey),
        );
      },
    );
  }

  Future<void> _updateFlowSchool(int? schoolId, {required bool isA}) async {
    if (_currentFlow == null) return;
    final companion = isA
        ? FlowCompanion(schoolAId: drift.Value(schoolId))
        : FlowCompanion(schoolBId: drift.Value(schoolId));

    await (database.update(database.flow)
          ..where((t) => t.id.equals(_currentFlow!.id)))
        .write(companion);

    final updated = await (database.select(database.flow)
          ..where((t) => t.id.equals(_currentFlow!.id)))
        .getSingle();

    setState(() {
      _currentFlow = updated;
    });
  }

  Future<void> _showAddSchoolDialog() async {
    final nameCtrl = TextEditingController();
    File? pickedLogo;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加学校 (Add School)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '学校名称'),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  final res =
                      await FilePicker.platform.pickFiles(type: FileType.image);
                  if (res != null && res.files.single.path != null) {
                    setDialogState(
                        () => pickedLogo = File(res.files.single.path!));
                  }
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: pickedLogo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(pickedLogo!, fit: BoxFit.cover))
                      : const Icon(Icons.add_photo_alternate,
                          color: Colors.grey),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                int? imgId;
                if (pickedLogo != null) {
                  final supportDir = await getApplicationSupportDirectory();
                  final schoolDir = Directory(p.join(supportDir.path,
                      'YiHuaTimer', 'schools', widget.event.id.toString()));
                  if (!await schoolDir.exists())
                    await schoolDir.create(recursive: true);

                  final ext = p.extension(pickedLogo!.path);
                  final fName =
                      'logo_${DateTime.now().millisecondsSinceEpoch}$ext';
                  await pickedLogo!.copy(p.join(schoolDir.path, fName));

                  imgId = await database.into(database.images).insert(
                      ImagesCompanion.insert(
                          imageName: drift.Value(fName),
                          imageType: const drift.Value('schoolLogo')));
                }

                await database.into(database.school).insert(
                    SchoolCompanion.insert(
                        schoolName: name,
                        eventId: widget.event.id,
                        logoImageId: drift.Value(imgId)));

                if (mounted) Navigator.pop(context);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}
