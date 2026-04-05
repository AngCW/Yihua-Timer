import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../FlowManager/flow_manager_page.dart';
import '../main.dart';
import 'package:drift/drift.dart' as drift;
import 'package:reorderables/reorderables.dart';
import 'clipboard_manager.dart';
import 'flow_utils.dart';

class EventFolderDetailPage extends StatefulWidget {
  final EventData event;
  final FlowFolderData folder;

  const EventFolderDetailPage({
    super.key,
    required this.event,
    required this.folder,
  });

  @override
  State<EventFolderDetailPage> createState() => _EventFolderDetailPageState();
}

class _EventFolderDetailPageState extends State<EventFolderDetailPage> {
  Future<int> _getFolderDepth(int folderId) async {
    int depth = 1;
    int? currentParent = folderId;
    while (currentParent != null) {
      final parentFolder = await (database.select(database.flowFolder)
            ..where((t) => t.id.equals(currentParent!)))
          .getSingleOrNull();
      if (parentFolder == null) break;
      depth++;
      currentParent = parentFolder.parentFolderId;
    }
    return depth;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('${widget.event.eventName} - ${widget.folder.folderName}'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Folders Section
            _buildSectionTitle('子文件夹 (Subfolders)'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: StreamBuilder<List<FlowFolderData>>(
                stream: (database.select(database.flowFolder)
                      ..where((t) => t.eventId.equals(widget.event.id))
                      ..where((t) => t.parentFolderId.equals(widget.folder.id))
                      ..orderBy([(t) => drift.OrderingTerm(expression: t.folderPosition)]))
                    .watch(),
                builder: (context, snapshot) {
                  final folders = snapshot.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (folders.isNotEmpty) ...[
                        ReorderableWrap(
                          needsLongPressDraggable: false,
                          spacing: 16.0,
                          runSpacing: 16.0,
                          onReorder: (oldIndex, newIndex) => _reorderFolders(folders, oldIndex, newIndex),
                          children: [
                            ...folders.map((folder) => Container(
                                  key: ValueKey(folder.id),
                                  child: _buildFolderBox(context, folder),
                                )),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          _buildAddFolderButton(context),
                          if (ClipboardManager.copiedFolder != null) ...[
                            const SizedBox(width: 16),
                            _buildPasteFolderButton(context),
                          ],
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 40),

            _buildSectionTitle('文件夹内赛程 (Flows in Folder)'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: StreamBuilder<List<FlowData>>(
                stream: (database.select(database.flow)
                      ..where((t) => t.folderId.equals(widget.folder.id))
                      ..orderBy([
                        (t) => drift.OrderingTerm(expression: t.flowPosition)
                      ]))
                    .watch(),
                builder: (context, snapshot) {
                  final flows = snapshot.data ?? [];
                  return Column(
                    children: [
                      if (flows.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ReorderableWrap(
                            needsLongPressDraggable: false,
                            spacing: 16.0,
                            runSpacing: 16.0,
                            onReorder: (oldIndex, newIndex) {
                              _reorderFlows(flows, oldIndex, newIndex);
                            },
                            children: [
                              ...flows.map((flow) => Container(
                                    key: ValueKey(flow.id),
                                    child: _buildFlowBox(context, flow),
                                  )),
                            ],
                          ),
                        ),
                      if (flows.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Text('此文件夹暂无赛程'),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildAddFlowButton(context),
                          if (ClipboardManager.copiedFlow != null) ...[
                            const SizedBox(width: 16),
                            _buildPasteFlowButton(context),
                          ],
                        ],
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

  Future<void> _reorderFlows(
      List<FlowData> flows, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = flows.removeAt(oldIndex);
    flows.insert(newIndex, item);

    for (int i = 0; i < flows.length; i++) {
      await (database.update(database.flow)
            ..where((t) => t.id.equals(flows[i].id)))
          .write(FlowCompanion(flowPosition: drift.Value(i + 1)));
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildFlowBox(BuildContext context, FlowData flow) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showFlowContextMenu(context, flow, details.globalPosition);
      },
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FlowManagerPage(event: widget.event, initialFlow: flow),
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
                  color: const Color(0xFF6B46C1).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B46C1).withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.alt_route_rounded,
                size: 32,
                color: Color(0xFF6B46C1),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 90,
              child: Tooltip(
                message: flow.flowName ?? '未命名',
                child: Text(
                  flow.flowName ?? '未命名',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFlowContextMenu(
      BuildContext context, FlowData flow, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.copy_rounded, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('复制赛程', style: TextStyle(color: Colors.blue)),
            ],
          ),
          onTap: () {
            setState(() => ClipboardManager.copiedFlow = flow);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已复制赛程: ${flow.flowName}')),
            );
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.delete_rounded, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('删除赛程', style: TextStyle(color: Colors.red)),
            ],
          ),
          onTap: () => _deleteFlow(flow),
        ),
      ],
    );
  }

  Future<void> _reorderFolders(
      List<FlowFolderData> folders, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = folders.removeAt(oldIndex);
    folders.insert(newIndex, item);

    for (int i = 0; i < folders.length; i++) {
      await (database.update(database.flowFolder)
            ..where((t) => t.id.equals(folders[i].id)))
          .write(FlowFolderCompanion(folderPosition: drift.Value(i + 1)));
    }
  }

  Widget _buildFolderBox(BuildContext context, FlowFolderData folder) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showFolderContextMenu(context, folder, details.globalPosition);
      },
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EventFolderDetailPage(event: widget.event, folder: folder),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: folder.folderName,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.shade200,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  size: 40,
                  color: Colors.amber,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 90,
              child: Tooltip(
                message: folder.folderName,
                child: Text(
                  folder.folderName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderContextMenu(
      BuildContext context, FlowFolderData folder, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('重命名文件夹', style: TextStyle(color: Colors.blue)),
            ],
          ),
          onTap: () => Future.delayed(
            const Duration(milliseconds: 100),
            () => _renameFolder(folder),
          ),
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.copy_rounded, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('复制文件夹', style: TextStyle(color: Colors.blue)),
            ],
          ),
          onTap: () {
            setState(() => ClipboardManager.copiedFolder = folder);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已复制文件夹: ${folder.folderName}')),
            );
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.delete_rounded, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('删除文件夹', style: TextStyle(color: Colors.red)),
            ],
          ),
          onTap: () => _deleteFolder(folder),
        ),
      ],
    );
  }

  Future<void> _renameFolder(FlowFolderData folder) async {
    final controller = TextEditingController(text: folder.folderName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名文件夹'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '文件夹名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      await (database.update(database.flowFolder)
            ..where((t) => t.id.equals(folder.id)))
          .write(FlowFolderCompanion(
              folderName: drift.Value(controller.text.trim())));
      if (mounted) setState(() {});
    }
  }

  Future<void> _deleteFolder(FlowFolderData folder) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('确认删除'),
              content:
                  Text('确认要删除文件夹 "${folder.folderName}" 吗？此操作将删除其内部所有资源。'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('确认删除',
                        style: TextStyle(color: Colors.red))),
              ],
            ));

    if (confirmed == true) {
      try {
        await FlowUtils.deleteFolderRecursive(folder.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('文件夹已删除')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  Future<void> _deleteFlow(FlowData flow) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('确认删除'),
              content: Text('确认要删除赛程 "${flow.flowName}" 吗？此操作将删除该赛程下的所有页面和数据。'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('确认删除',
                        style: TextStyle(color: Colors.red))),
              ],
            ));

    if (confirmed == true) {
      try {
        final allFlows = await (database.select(database.flow)
              ..where((t) => t.folderId.equals(widget.folder.id))
              ..orderBy(
                  [(t) => drift.OrderingTerm(expression: t.flowPosition)]))
            .get();

        final flowPages = await (database.select(database.page)
              ..where((t) => t.flowId.equals(flow.id)))
            .get();
        for (final p in flowPages) {
          await (database.delete(database.timer)
                ..where((t) => t.pageId.equals(p.id)))
              .go();
          await (database.delete(database.images)
                ..where((t) => t.pageId.equals(p.id)))
              .go();
          await (database.delete(database.page)
                ..where((t) => t.id.equals(p.id)))
              .go();
        }

        await (database.delete(database.flow)
              ..where((t) => t.id.equals(flow.id)))
            .go();

        int pos = 1;
        for (final f in allFlows) {
          if (f.id == flow.id) continue;
          await (database.update(database.flow)
                ..where((t) => t.id.equals(f.id)))
              .write(FlowCompanion(flowPosition: drift.Value(pos++)));
        }

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('赛程已删除')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('删除失败: $e')));
        }
      }
    }
  }

  Future<void> _createDefaultPages(int flowId) async {
    final templates = await database.select(database.timerTemplate).get();
    final tid = templates.isNotEmpty ? templates.first.id : null;

    Future<void> insPage(String n, String pt, int p,
        {bool uf = false,
        String? sn,
        bool wt = false,
        bool isDefault = true,
        String? hk}) async {
      final pg = await database.into(database.page).insertReturning(
            PageCompanion.insert(
              pageName: drift.Value(n),
              flowId: drift.Value(flowId),
              pagePosition: drift.Value(p),
              pageTypeId: drift.Value(pt),
              useFrontpage: drift.Value(uf),
              sectionName: drift.Value(sn),
              isDefaultPage: drift.Value(isDefault),
              hotkeyValue: drift.Value(hk),
            ),
          );
      if (wt && tid != null) {
        await database.into(database.timer).insert(TimerCompanion.insert(
            pageId: drift.Value(pg.id),
            timerTemplateId: drift.Value(tid),
            timerType: const drift.Value('single'),
            startTime: const drift.Value('2:0')));
      }
    }

    await insPage('主页', 'C', 1, uf: true, isDefault: false);
    await insPage('断线缓冲计时环节', 'A1', 2, sn: '断线缓冲计时环节', wt: true, hk: '1');
    await insPage('断线缓冲标题页面', 'B', 3, sn: '断线缓冲标题页面', hk: '2');
    await insPage('立场捍卫环节', 'A1', 4, sn: '立场捍卫环节', wt: true, hk: '3');
    await insPage('资料检证环节', 'A1', 5, sn: '资料检证环节', wt: true, hk: '4');
  }

  Widget _buildAddFlowButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        final flows = await (database.select(database.flow)
              ..where((t) => t.folderId.equals(widget.folder.id)))
            .get();

        final newFlow = await database.into(database.flow).insertReturning(
              FlowCompanion.insert(
                flowName: const drift.Value('未命名'),
                eventId: drift.Value(widget.event.id),
                folderId: drift.Value(widget.folder.id),
                flowPosition: drift.Value(flows.length + 1),
              ),
            );

        await _createDefaultPages(newFlow.id);

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FlowManagerPage(event: widget.event, initialFlow: newFlow),
            ),
          );
        }
      },
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
              '添加赛程',
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

  Widget _buildPasteFlowButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (ClipboardManager.copiedFlow == null) return;
        final flows = await (database.select(database.flow)
              ..where((t) => t.folderId.equals(widget.folder.id)))
            .get();
        await FlowUtils.duplicateFlow(
            ClipboardManager.copiedFlow!, widget.event.id,
            folderId: widget.folder.id, position: flows.length + 1);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.2),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: const Icon(
              Icons.paste_rounded,
              size: 32,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 80,
            child: Text(
              '粘贴赛程',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFolderButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        final depth = await _getFolderDepth(widget.folder.id);
        if (depth >= 5) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('最多只支持 5 层文件夹嵌套限制。')),
            );
          }
          return;
        }

        final folders = await (database.select(database.flowFolder)
              ..where((t) => t.eventId.equals(widget.event.id))
              ..where((t) => t.parentFolderId.equals(widget.folder.id)))
            .get();

        await database.into(database.flowFolder).insertReturning(
              FlowFolderCompanion.insert(
                folderName: '新建文件夹',
                eventId: widget.event.id,
                folderPosition: folders.length + 1,
                parentFolderId: drift.Value(widget.folder.id),
              ),
            );

        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('文件夹已创建')));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.2),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: const Icon(
              Icons.create_new_folder_rounded,
              size: 32,
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 80,
            child: Text(
              '新建子文件夹',
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

  Widget _buildPasteFolderButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (ClipboardManager.copiedFolder == null) return;
        final depth = await _getFolderDepth(widget.folder.id);
        if (depth >= 5) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('最多只支持 5 层文件夹嵌套限制。')),
            );
          }
          return;
        }

        final folders = await (database.select(database.flowFolder)
              ..where((t) => t.eventId.equals(widget.event.id))
              ..where((t) => t.parentFolderId.equals(widget.folder.id)))
            .get();

        final newFolder = await database.into(database.flowFolder).insertReturning(
              FlowFolderCompanion.insert(
                folderName: '${ClipboardManager.copiedFolder!.folderName} (副本)',
                eventId: widget.event.id,
                folderPosition: folders.length + 1,
                parentFolderId: drift.Value(widget.folder.id),
              ),
            );

        // Recursive duplication logic is simplified to just direct flows for now
        final flowsInFolder = await (database.select(database.flow)
              ..where((t) => t.folderId.equals(ClipboardManager.copiedFolder!.id)))
            .get();

        for (final flow in flowsInFolder) {
          await FlowUtils.duplicateFlow(flow, widget.event.id,
              folderId: newFolder.id, position: flow.flowPosition!);
        }
        setState(() {});
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.2),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: const Icon(
              Icons.paste_rounded,
              size: 32,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 80,
            child: Text(
              '粘贴文件夹',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
