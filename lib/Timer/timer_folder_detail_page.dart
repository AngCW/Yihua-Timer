import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../main.dart';
import 'package:drift/drift.dart' as drift;
import 'timer_runner_page.dart';

class TimerFolderDetailPage extends StatefulWidget {
  final EventData event;
  final FlowFolderData folder;

  const TimerFolderDetailPage({
    super.key,
    required this.event,
    required this.folder,
  });

  @override
  State<TimerFolderDetailPage> createState() => _TimerFolderDetailPageState();
}

class _TimerFolderDetailPageState extends State<TimerFolderDetailPage> {
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
              child: StreamBuilder<List<FlowData>>(
                stream: (database.select(database.flow)
                      ..where((t) => t.folderId.equals(widget.folder.id))
                      ..orderBy([
                        (t) => drift.OrderingTerm(expression: t.flowPosition)
                      ]))
                    .watch(),
                builder: (context, snapshot) {
                  final flows = snapshot.data ?? [];
                  if (flows.isEmpty) {
                    return const Center(child: Text('此文件夹暂无赛程'));
                  }
                  return SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: flows.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: _buildFlowBox(context, flows[index]),
                        );
                      },
                    ),
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
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
        letterSpacing: -0.5,
      ),
    );
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
}
