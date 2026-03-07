import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../FlowManager/flow_manager_page.dart';
import '../main.dart';
import 'package:drift/drift.dart' as drift;

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
                                      padding:
                                          const EdgeInsets.only(right: 16.0),
                                      child: _buildFlowBox(context, flow),
                                    ),
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildAddFlowButton(context),
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
}
