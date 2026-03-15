import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../database/app_database.dart';
import '../../Timer/timer_event_detail_page.dart';
import '../../Timer/timer_runner_page.dart';

class EventScheduleSidebar extends StatelessWidget {
  const EventScheduleSidebar({super.key});

  static const List<Color> _scheduleColors = [
    Color(0xFFD1FAE5),
    Color(0xFFFEF3C7),
    Color(0xFFFED7AA),
    Color(0xFFFEE2E2),
    Color(0xFFE0E7FF),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border(
          left: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: const Text(
              '赛事时间表',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
                letterSpacing: -0.3,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<EventData>>(
              stream: (database.select(database.event)
                    ..orderBy([
                      (t) => drift.OrderingTerm(
                            expression: t.startDate,
                            mode: drift.OrderingMode.asc,
                          ),
                    ]))
                  .watch(),
              builder: (context, eventSnapshot) {
                final events = eventSnapshot.data ?? [];
                if (events.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '暂无赛事',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return StreamBuilder<List<FlowFolderData>>(
                  stream: database.select(database.flowFolder).watch(),
                  builder: (context, folderSnapshot) {
                    final allFolders = folderSnapshot.data ?? [];
                    final folderMap = {for (var f in allFolders) f.id: f.folderName};
                    
                    return StreamBuilder<List<FlowData>>(
                      stream: database.select(database.flow).watch(),
                      builder: (context, flowSnapshot) {
                        final allFlows = flowSnapshot.data ?? [];
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int e = 0; e < events.length; e++) ...[
                                _EventBlock(
                                  event: events[e],
                                  flows: allFlows
                                      .where((f) => f.eventId == events[e].id)
                                      .toList()
                                    ..sort((a, b) =>
                                        (a.flowPosition ?? 0)
                                            .compareTo(b.flowPosition ?? 0)),
                                  folderMap: folderMap,
                                  scheduleColors: _scheduleColors,
                                ),
                                if (e < events.length - 1) const SizedBox(height: 28),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EventBlock extends StatelessWidget {
  const _EventBlock({
    required this.event,
    required this.flows,
    required this.folderMap,
    required this.scheduleColors,
  });

  final EventData event;
  final List<FlowData> flows;
  final Map<int, String> folderMap;
  final List<Color> scheduleColors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) =>
                    TimerEventDetailPage(event: event),
              ),
            );
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              event.eventName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (flows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '暂无赛程',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          )
        else
          ..._buildGroupedFlows(context),
      ],
    );
  }

  List<Widget> _buildGroupedFlows(BuildContext context) {
    List<Widget> items = [];
    int? currentFolderId;
    final dateStr = event.startDate != null
        ? DateFormat('dd/MM/yyyy').format(event.startDate!)
        : '—';

    for (int i = 0; i < flows.length; i++) {
      final flow = flows[i];
      
      if (flow.folderId != currentFolderId) {
        if (flow.folderId != null) {
          final folderName = folderMap[flow.folderId];
          if (folderName != null) {
            items.add(
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        folderName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4B5563),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
        currentFolderId = flow.folderId;
      }

      items.add(
        _ScheduleItem(
          stage: flow.flowName ?? '未命名',
          date: dateStr,
          backgroundColor: scheduleColors[i % scheduleColors.length],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => TimerRunnerPage(
                  event: event,
                  flow: flow,
                ),
              ),
            );
          },
        ),
      );
    }
    return items;
  }
}

class _ScheduleItem extends StatelessWidget {
  const _ScheduleItem({
    required this.stage,
    required this.date,
    this.backgroundColor,
    this.onTap,
  });

  final String stage;
  final String date;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    stage,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
