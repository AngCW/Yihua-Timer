import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../FlowManager/flow_manager_page.dart';
import 'event_folder_detail_page.dart';
import '../main.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class EventDetailsPage extends StatefulWidget {
  final EventData event;

  const EventDetailsPage({super.key, required this.event});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  static FlowData? _copiedFlow;
  static FlowFolderData? _copiedFolder;

  @override
  Widget build(BuildContext context) {
    final dateRange = (widget.event.startDate != null &&
            widget.event.endDate != null)
        ? '${DateFormat('yyyy-MM-dd').format(widget.event.startDate!)} ~ ${DateFormat('yyyy-MM-dd').format(widget.event.endDate!)}'
        : '未设置日期';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(widget.event.eventName),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('赛事详情'),
                TextButton.icon(
                  onPressed: _showEditEventDialog,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('编辑详情'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B46C1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildInfoRow('赛事名称', widget.event.eventName),
                    _buildDivider(),
                    _buildInfoRow('赛制简介', widget.event.eventDesc ?? '无'),
                    _buildDivider(),
                    _buildInfoRow('赛事日期', dateRange),
                    _buildDivider(),
                    _buildInfoRow('参赛队数量', '${widget.event.teamNum ?? 0}'),
                    _buildDivider(),
                    _buildInfoRow('备注', widget.event.remark ?? '无'),
                  ],
                ),
              ),
            ),

            _buildSchoolsSection(),
            const SizedBox(height: 40),

            // Event Flow Section (Rectangle defining the flow)
            _buildSectionTitle('赛程流 (Event Flow)'),
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
              child: Column(
                children: [
                  // Folders Section
                  StreamBuilder<List<FlowFolderData>>(
                    stream: (database.select(database.flowFolder)
                          ..where((t) => t.eventId.equals(widget.event.id))
                          ..orderBy([
                            (t) =>
                                drift.OrderingTerm(expression: t.folderPosition)
                          ]))
                        .watch(),
                    builder: (context, snapshot) {
                      final folders = snapshot.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (folders.isNotEmpty) ...[
                            const Text('文件夹',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 160,
                              child: ReorderableListView(
                                scrollDirection: Axis.horizontal,
                                onReorder: (oldIndex, newIndex) {
                                  _reorderFolders(folders, oldIndex, newIndex);
                                },
                                children: [
                                  ...folders.map((folder) =>
                                      ReorderableDelayedDragStartListener(
                                        key: ValueKey(folder.id),
                                        index: folders.indexOf(folder),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 16.0),
                                          child:
                                              _buildFolderBox(context, folder),
                                        ),
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              _buildAddFolderButton(context),
                              if (_copiedFolder != null) ...[
                                const SizedBox(width: 16),
                                _buildPasteFolderButton(context),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),

                  // Outermost Flows Section
                  StreamBuilder<List<FlowData>>(
                    stream: (database.select(database.flow)
                          ..where((t) => t.eventId.equals(widget.event.id))
                          ..where((t) => t.folderId.isNull())
                          ..orderBy([
                            (t) =>
                                drift.OrderingTerm(expression: t.flowPosition)
                          ]))
                        .watch(),
                    builder: (context, snapshot) {
                      final flows = snapshot.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (flows.isNotEmpty) ...[
                            const Text('独立赛程',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 160,
                              child: ReorderableListView(
                                scrollDirection: Axis.horizontal,
                                onReorder: (oldIndex, newIndex) {
                                  _reorderFlows(flows, oldIndex, newIndex);
                                },
                                children: [
                                  ...flows.map((flow) =>
                                      ReorderableDelayedDragStartListener(
                                        key: ValueKey(flow.id),
                                        index: flows.indexOf(flow),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 16.0),
                                          child: _buildFlowBox(context, flow),
                                        ),
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              _buildAddFlowButton(context),
                              if (_copiedFlow != null) ...[
                                const SizedBox(width: 16),
                                _buildPasteFlowButton(context),
                              ],
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditEventDialog() async {
    final e = widget.event;
    final nameCtrl = TextEditingController(text: e.eventName);
    final descCtrl = TextEditingController(text: e.eventDesc);
    final teamCtrl = TextEditingController(text: e.teamNum?.toString() ?? '');
    final remarkCtrl = TextEditingController(text: e.remark);
    DateTimeRange? range = (e.startDate != null && e.endDate != null)
        ? DateTimeRange(start: e.startDate!, end: e.endDate!)
        : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑赛事详情'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: '赛事名称')),
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: '赛制简介')),
                TextField(
                    controller: teamCtrl,
                    decoration: const InputDecoration(labelText: '参赛队数量'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: remarkCtrl,
                    decoration: const InputDecoration(labelText: '备注')),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(range == null
                      ? '点击选择日期范围'
                      : '${DateFormat('yyyy-MM-dd').format(range!.start)} ~ ${DateFormat('yyyy-MM-dd').format(range!.end)}'),
                  trailing: const Icon(Icons.calendar_month_rounded),
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: range,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => range = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6B46C1)),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final updated = e.copyWith(
        eventName: nameCtrl.text.trim(),
        eventDesc: drift.Value(descCtrl.text.trim()),
        teamNum: drift.Value(int.tryParse(teamCtrl.text)),
        remark: drift.Value(remarkCtrl.text.trim()),
        startDate: drift.Value(range?.start),
        endDate: drift.Value(range?.end),
      );
      await database.update(database.event).replace(updated);
      setState(() {
        // Since we passed widget.event (final), we might need to refresh state
        // or the parent might watch the DB. EventDetailsPage takes event.
        // It's better to navigate back or re-fetch.
        // For now, let's assume it's fine if we rebuild.
      });
      if (mounted) {
        Navigator.pop(context); // Optional: if we want to refresh completely
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => EventDetailsPage(event: updated)),
        );
      }
    }
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 24, color: Colors.grey.shade100);
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
            setState(() => _copiedFolder = folder);
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
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _deleteFolder(FlowFolderData folder) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('确认删除'),
              content:
                  Text('确认要删除文件夹 "${folder.folderName}" 吗？此操作将删除其内部所有赛程和数据。'),
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
        final folderFlows = await (database.select(database.flow)
              ..where((t) => t.folderId.equals(folder.id)))
            .get();

        for (final flow in folderFlows) {
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
        }

        await (database.delete(database.flowFolder)
              ..where((t) => t.id.equals(folder.id)))
            .go();

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('文件夹已删除')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('删除失败: $e')));
        }
      }
    }
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
            setState(() => _copiedFlow = flow);
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
        // Renumber others
        final allFlows = await (database.select(database.flow)
              ..where((t) => t.eventId.equals(widget.event.id))
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

  Widget _buildAddFolderButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        final folders = await (database.select(database.flowFolder)
              ..where((t) => t.eventId.equals(widget.event.id)))
            .get();

        await database.into(database.flowFolder).insertReturning(
              FlowFolderCompanion.insert(
                folderName: '新建文件夹',
                eventId: widget.event.id,
                folderPosition: folders.length + 1,
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
              '新建文件夹',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFD97706),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFlowButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        final flows = await (database.select(database.flow)
              ..where((t) => t.eventId.equals(widget.event.id)))
            .get();

        final newFlow = await database.into(database.flow).insertReturning(
              FlowCompanion.insert(
                flowName: const drift.Value('未命名'),
                eventId: drift.Value(widget.event.id),
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
        if (_copiedFlow == null) return;
        final flows = await (database.select(database.flow)
              ..where((t) => t.eventId.equals(widget.event.id)))
            .get();
        await _duplicateFlow(_copiedFlow!, null, flows.length + 1);
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

  Widget _buildPasteFolderButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (_copiedFolder == null) return;
        final folders = await (database.select(database.flowFolder)
              ..where((t) => t.eventId.equals(widget.event.id)))
            .get();

        final newFolder =
            await database.into(database.flowFolder).insertReturning(
                  FlowFolderCompanion.insert(
                    folderName: '${_copiedFolder!.folderName} (副本)',
                    eventId: widget.event.id,
                    folderPosition: folders.length + 1,
                  ),
                );

        final flowsInFolder = await (database.select(database.flow)
              ..where((t) => t.folderId.equals(_copiedFolder!.id)))
            .get();

        for (final flow in flowsInFolder) {
          await _duplicateFlow(flow, newFolder.id, flow.flowPosition!);
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

  Future<void> _duplicateFlow(
      FlowData flow, int? folderId, int position) async {
    final newFlow = await database.into(database.flow).insertReturning(
          FlowCompanion.insert(
            flowName: drift.Value('${flow.flowName} (副本)'),
            eventId: drift.Value(widget.event.id),
            flowPosition: drift.Value(position),
            folderId: drift.Value(folderId),
            fontName: drift.Value(flow.fontName),
            sectionFontName: drift.Value(flow.sectionFontName),
            timerFontName: drift.Value(flow.timerFontName),
            frontpageName: drift.Value(flow.frontpageName),
            backgroundName: drift.Value(flow.backgroundName),
          ),
        );

    final pages = await (database.select(database.page)
          ..where((t) => t.flowId.equals(flow.id)))
        .get();

    for (final page in pages) {
      final newPage = await database.into(database.page).insertReturning(
            PageCompanion.insert(
              pageName: drift.Value(page.pageName),
              flowId: drift.Value(newFlow.id),
              pagePosition: drift.Value(page.pagePosition),
              pageTypeId: drift.Value(page.pageTypeId),
              sectionName: drift.Value(page.sectionName),
              bgmId: drift.Value(page.bgmId),
              hotkeyValue: drift.Value(page.hotkeyValue),
              sectionXpos: drift.Value(page.sectionXpos),
              sectionYpos: drift.Value(page.sectionYpos),
              sectionScale: drift.Value(page.sectionScale),
              sectionFontName: drift.Value(page.sectionFontName),
              timerFontName: drift.Value(page.timerFontName),
              useFrontpage: drift.Value(page.useFrontpage),
              isDefaultPage: drift.Value(page.isDefaultPage),
            ),
          );

      // Copy timers
      final timers = await (database.select(database.timer)
            ..where((t) => t.pageId.equals(page.id)))
          .get();
      for (final timer in timers) {
        await database.into(database.timer).insert(
              TimerCompanion.insert(
                pageId: drift.Value(newPage.id),
                timerTemplateId: drift.Value(timer.timerTemplateId),
                startTime: drift.Value(timer.startTime),
                timerType: drift.Value(timer.timerType),
                xpos: drift.Value(timer.xpos),
                ypos: drift.Value(timer.ypos),
                scale: drift.Value(timer.scale),
              ),
            );
      }

      // Copy images
      final images = await (database.select(database.images)
            ..where((t) => t.pageId.equals(page.id)))
          .get();
      for (final img in images) {
        await database.into(database.images).insert(
              ImagesCompanion.insert(
                imageName: drift.Value(img.imageName),
                imageType: drift.Value(img.imageType),
                pageId: drift.Value(newPage.id),
              ),
            );
      }
    }
  }

  Widget _buildSchoolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('参赛学校 (Schools)'),
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
          child: StreamBuilder<List<SchoolData>>(
            stream: (database.select(database.school)
                  ..where((t) => t.eventId.equals(widget.event.id)))
                .watch(),
            builder: (context, snapshot) {
              final schools = snapshot.data ?? [];
              return Wrap(
                spacing: 16,
                runSpacing: 24,
                children: [
                  ...schools.map((s) => _buildSchoolCard(s)),
                  _buildAddSchoolButton(context),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddSchoolButton(BuildContext context) {
    return InkWell(
      onTap: _showAddSchoolDialog,
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
              '添加学校',
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

  Widget _buildSchoolCard(SchoolData school) {
    return FutureBuilder<ImagesData?>(
      future: school.logoImageId != null
          ? (database.select(database.images)
                ..where((t) => t.id.equals(school.logoImageId!)))
              .getSingleOrNull()
          : Future.value(null),
      builder: (context, imgSnapshot) {
        final img = imgSnapshot.data;
        return Container(
          width: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  shape: BoxShape.circle,
                ),
                child: img != null
                    ? FutureBuilder<Directory>(
                        future: getApplicationSupportDirectory(),
                        builder: (context, dirSnapshot) {
                          if (!dirSnapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          final path = p.join(
                            dirSnapshot.data!.path,
                            'YiHuaTimer',
                            'schools',
                            widget.event.id.toString(),
                            img.imageName!,
                          );
                          final file = File(path);
                          if (!file.existsSync()) {
                            return const Icon(Icons.broken_image_rounded,
                                color: Colors.grey, size: 32);
                          }
                          return ClipOval(
                            child: Image.file(file, fit: BoxFit.cover),
                          );
                        },
                      )
                    : const Icon(Icons.school_rounded,
                        color: Colors.grey, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                school.schoolName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddSchoolDialog() async {
    final nameCtrl = TextEditingController();
    File? pickedLogo;
    String? pickedLogoName;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加学校 (Add School)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '学校名称',
                  hintText: '输入学校全称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              const Text('学校 Logo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final result =
                      await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null && result.files.single.path != null) {
                    setDialogState(() {
                      pickedLogo = File(result.files.single.path!);
                      pickedLogoName = result.files.single.name;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: pickedLogo != null
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(pickedLogo!, fit: BoxFit.cover),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.edit,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                color: Colors.grey, size: 32),
                            SizedBox(height: 4),
                            Text('上传 Logo',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              if (pickedLogoName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(pickedLogoName!,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('请输入学校名称')));
                  return;
                }

                try {
                  int? imgId;
                  if (pickedLogo != null) {
                    final supportDir = await getApplicationSupportDirectory();
                    final schoolDir = Directory(p.join(supportDir.path,
                        'YiHuaTimer', 'schools', widget.event.id.toString()));
                    if (!await schoolDir.exists()) {
                      await schoolDir.create(recursive: true);
                    }

                    final fileName =
                        'logo_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedLogo!.path)}';
                    final targetPath = p.join(schoolDir.path, fileName);
                    await pickedLogo!.copy(targetPath);

                    imgId = await database.into(database.images).insert(
                          ImagesCompanion.insert(
                            imageName: drift.Value(fileName),
                            imageType: const drift.Value('schoolLogo'),
                          ),
                        );
                  }

                  await database.into(database.school).insert(
                        SchoolCompanion.insert(
                          schoolName: name,
                          eventId: widget.event.id,
                          logoImageId: drift.Value(imgId),
                        ),
                      );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('学校已添加')));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('保存失败: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B46C1),
                  foregroundColor: Colors.white),
              child: const Text('添加学校'),
            ),
          ],
        ),
      ),
    );
  }
}
