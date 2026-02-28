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

            // Pages Selection
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
}
