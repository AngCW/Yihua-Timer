import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../database/app_database.dart';
import '../../Timer/timer_event_detail_page.dart';

class RecentEventsSection extends StatefulWidget {
  const RecentEventsSection({
    super.key,
    this.onViewAll,
  });

  /// Called when "查看全部" is tapped; e.g. switch to 已保存赛事 (Event Manager).
  final VoidCallback? onViewAll;

  @override
  State<RecentEventsSection> createState() => _RecentEventsSectionState();
}

class _RecentEventsSectionState extends State<RecentEventsSection> {
  static const int _maxDisplay = 3;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EventData>>(
      future: _loadEventsAscending(),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        final hasData = events.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '最近赛事',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onViewAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '查看全部',
                      style: TextStyle(
                        color: Color(0xFF6B46C1),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!snapshot.hasData)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (!hasData)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '暂无已保存赛事',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (int i = 0;
                        i < events.length && i < _maxDisplay;
                        i++)
                      SizedBox(
                        width: 260,
                        child: _EventCard(
                          event: events[i],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) =>
                                    TimerEventDetailPage(event: events[i]),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  /// Load saved events from database, ordered by start_date ascending.
  Future<List<EventData>> _loadEventsAscending() async {
    final query = database.select(database.event)
      ..orderBy([
        (t) => drift.OrderingTerm(
              expression: t.startDate,
              mode: drift.OrderingMode.asc,
            ),
      ]);
    final list = await query.get();
    return list;
  }
}

class _EventCard extends StatelessWidget {
  final EventData event;
  final VoidCallback? onTap;

  const _EventCard({
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final start = event.startDate;
    final end = event.endDate;

    String dateStr;
    if (start != null && end != null) {
      dateStr =
          '${DateFormat('dd/MM/yyyy').format(start)} ~ ${DateFormat('dd/MM/yyyy').format(end)}';
    } else if (start != null) {
      dateStr = DateFormat('dd/MM/yyyy').format(start);
    } else {
      dateStr = '未设置日期';
    }

    String? timeStr;
    if (start != null && end != null) {
      final bothMidnight =
          start.hour == 0 && start.minute == 0 && end.hour == 0 && end.minute == 0;
      if (!bothMidnight) {
        timeStr =
            '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}';
      }
    }
    final participantCount = event.teamNum ?? 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.eventName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (timeStr != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B46C1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 14, color: const Color(0xFF6B46C1)),
                      const SizedBox(width: 4),
                      Text(
                        '$participantCount',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B46C1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
