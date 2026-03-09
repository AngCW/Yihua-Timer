import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../main.dart';
import 'package:drift/drift.dart' as drift;
import 'timer_runner_page.dart';
import 'timer_folder_detail_page.dart';

class TimerEventDetailPage extends StatefulWidget {
  final EventData event;

  const TimerEventDetailPage({super.key, required this.event});

  @override
  State<TimerEventDetailPage> createState() => _TimerEventDetailPageState();
}

class _TimerEventDetailPageState extends State<TimerEventDetailPage> {
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
            _buildSectionTitle('赛事详情'),
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

            const SizedBox(height: 40),

            // Event Flow Section
            _buildSectionTitle('可用赛程 (Available Flows)'),
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
                      if (folders.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                for (int i = 0; i < folders.length; i++)
                                  ReorderableDelayedDragStartListener(
                                    key: ValueKey(folders[i].id),
                                    index: i,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 16.0),
                                      child: _buildFolderBox(context, folders[i]),
                                    ),
                                  ),
                              ],
                            ),
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
                      if (flows.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                for (int i = 0; i < flows.length; i++)
                                  ReorderableDelayedDragStartListener(
                                    key: ValueKey(flows[i].id),
                                    index: i,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 16.0),
                                      child: _buildFlowBox(context, flows[i]),
                                    ),
                                  ),
                              ],
                            ),
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
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TimerRunnerPage(event: widget.event, flow: flow),
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
                color: const Color(0xFF2563EB).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_circle_outline_rounded,
              size: 32,
              color: Color(0xFF2563EB),
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
    );
  }

  Widget _buildFolderBox(BuildContext context, FlowFolderData folder) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TimerFolderDetailPage(event: widget.event, folder: folder),
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
    );
  }
}
