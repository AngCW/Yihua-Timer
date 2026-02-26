import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../database/app_database.dart';
import '../main.dart';

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
  PageData? _selectedPage;
  List<ImagesData> _currentImages = [];
  String? _fontFile;
  String? _frontpageFile;
  String? _backgroundFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlow();
  }

  Future<void> _loadFlow() async {
    if (widget.initialFlow != null) {
      _currentFlow = widget.initialFlow;
      _flowNameController.text = _currentFlow!.flowName ?? '';
      _loadPagesAndHandleSelection();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPagesAndHandleSelection() async {
    final pages = await (database.select(database.page)
          ..where((t) => t.flowId.equals(_currentFlow!.id))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.pagePosition)]))
        .get();

    if (mounted) {
      setState(() {
        if (pages.isNotEmpty) {
          _selectedPage = pages.first;
          _loadSelectedPageAssets();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSelectedPageAssets() async {
    if (_selectedPage == null) return;

    final images = await (database.select(database.images)
          ..where((t) => t.pageId.equals(_selectedPage!.id)))
        .get();

    if (mounted) {
      setState(() {
        _currentImages = images;
      });
      // Pre-compute file existence for UI
      _updateFileExistence();
    }
  }

  Future<void> _updateFileExistence() async {
    final font = await _getImagePathFromData('font');
    final front = await _getImagePathFromData('frontpage');
    final back = await _getImagePathFromData('background');
    if (mounted) {
      setState(() {
        _fontFile = font;
        _frontpageFile = front;
        _backgroundFile = back;
      });
    }
  }

  Future<String?> _getImagePathFromData(String type) async {
    try {
      ImagesData? img;
      for (final i in _currentImages) {
        if (i.imageType == type) {
          img = i;
          break;
        }
      }

      if (img == null || img.imageName == null) return null;

      final supportDir = await getApplicationSupportDirectory();
      final filePath = p.join(supportDir.path, 'YiHuaTimer', 'images',
          widget.event.id.toString(), img.imageName!);

      if (await File(filePath).exists()) {
        return img.imageName;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickAndSaveFile(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: type == 'font' ? FileType.any : FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      if (_selectedPage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先选择或添加一个页面')),
        );
        return;
      }

      final originalPath = result.files.single.path!;
      final extension = p.extension(result.files.single.name);
      final dbType = type == 'font'
          ? 'font'
          : (type == 'frontpage' ? 'frontpage' : 'background');

      // Rename to type identifier
      final fileName = '$dbType$extension';

      try {
        final supportDir = await getApplicationSupportDirectory();
        final imagesDir = Directory(p.join(supportDir.path, 'YiHuaTimer',
            'images', widget.event.id.toString()));

        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }

        // Check for existing entry of this type for this page
        final existing = _currentImages.where((img) => img.imageType == dbType);
        if (existing.isNotEmpty) {
          final oldImage = existing.first;
          // Delete old physical file (always delete to overwrite correctly)
          final oldFilePath = p.join(imagesDir.path, oldImage.imageName!);
          final oldFile = File(oldFilePath);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }

          await (database.update(database.images)
                ..where((t) => t.id.equals(oldImage.id)))
              .write(ImagesCompanion(imageName: drift.Value(fileName)));
        } else {
          await database.into(database.images).insert(ImagesCompanion.insert(
                imageName: drift.Value(fileName),
                imageType: drift.Value(dbType),
                pageId: drift.Value(_selectedPage!.id),
              ));
        }

        final targetPath = p.join(imagesDir.path, fileName);
        await File(originalPath).copy(targetPath);

        // Reload assets
        await _loadSelectedPageAssets();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${type == 'font' ? '字体' : '素材'}已更新: $fileName')),
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
              pagePosition: drift.Value(pages.length),
            ),
          );

      setState(() {
        _selectedPage = newPage;
        _loadSelectedPageAssets();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('新页面已添加')),
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

  Future<void> _saveFlowName() async {
    if (_flowNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入赛程名称')),
      );
      return;
    }

    try {
      if (_currentFlow == null) {
        // Create new flow
        final newFlow = await database.into(database.flow).insertReturning(
              FlowCompanion.insert(
                flowName: drift.Value(_flowNameController.text),
                eventId: drift.Value(widget.event.id),
              ),
            );
        setState(() {
          _currentFlow = newFlow;
        });
      } else {
        // Update existing flow
        await (database.update(database.flow)
              ..where((t) => t.id.equals(_currentFlow!.id)))
            .write(FlowCompanion(
          flowName: drift.Value(_flowNameController.text),
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('赛程名称已保存')),
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
            // Flow Name Input Section
            _buildSectionTitle('赛程名称 (Flow Name)'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _flowNameController,
                    decoration: InputDecoration(
                      hintText: '例如: 初赛第一场',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
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
                  label: const Text('保存名称'),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Assets Section
            _buildSectionTitle('素材管理 (Assets Management)'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildUploadBox(
                    label: '字体 (Font)',
                    icon: Icons.font_download_rounded,
                    onTap: () => _pickAndSaveFile('font'),
                    currentFile: _fontFile),
                _buildUploadBox(
                    label: '封面 (Front Page)',
                    icon: Icons.image_rounded,
                    onTap: () => _pickAndSaveFile('frontpage'),
                    currentFile: _frontpageFile),
                _buildUploadBox(
                    label: '背景 (Background)',
                    icon: Icons.wallpaper_rounded,
                    onTap: () => _pickAndSaveFile('background'),
                    currentFile: _backgroundFile),
              ],
            ),

            const SizedBox(height: 40),

            // Pages Section
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
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          children: [
                            ...pages.map((p) => _buildPageBox(context, p)),
                            _buildAddPageButton(context),
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
    final isSelected = _selectedPage?.id == page.id;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPage = page;
          _loadSelectedPageAssets();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6B46C1).withOpacity(0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected ? const Color(0xFF6B46C1) : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              Icons.description_rounded,
              size: 32,
              color:
                  isSelected ? const Color(0xFF6B46C1) : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            child: Text(
              page.pageName ?? '未命名',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? const Color(0xFF6B46C1)
                    : const Color(0xFF374151),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
