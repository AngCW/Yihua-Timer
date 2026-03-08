import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'event_details_page.dart';
import '../main.dart';
import '../database/app_database.dart';

class EventManagerPage extends StatefulWidget {
  const EventManagerPage({super.key});

  @override
  State<EventManagerPage> createState() => _EventManagerPageState();
}

class _EventManagerPageState extends State<EventManagerPage> {
  Future<void> _deleteEvent(EventData event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除赛事'),
        content: Text('确认要删除赛事 "${event.eventName}" 吗？此操作不可撤销，且会删除所有相关数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 1. Delete from database in a transaction
      await database.transaction(() async {
        // Delete schools (linked to event)
        final schools = await (database.select(database.school)
              ..where((t) => t.eventId.equals(event.id)))
            .get();
        for (var school in schools) {
          if (school.logoImageId != null) {
            final image = await (database.select(database.images)
                  ..where((t) => t.id.equals(school.logoImageId!)))
                .getSingleOrNull();
            if (image != null) {
              if (image.positionId != null) {
                await (database.delete(database.position)
                      ..where((t) => t.id.equals(image.positionId!)))
                    .go();
              }
              await (database.delete(database.images)
                    ..where((t) => t.id.equals(image.id)))
                  .go();
            }
          }
        }
        await (database.delete(database.school)
              ..where((t) => t.eventId.equals(event.id)))
            .go();

        // Delete flow folders
        await (database.delete(database.flowFolder)
              ..where((t) => t.eventId.equals(event.id)))
            .go();

        // Delete flows
        final flows = await (database.select(database.flow)
              ..where((t) => t.eventId.equals(event.id)))
            .get();
        for (var flow in flows) {
          // Delete pages
          final pages = await (database.select(database.page)
                ..where((t) => t.flowId.equals(flow.id)))
              .get();
          for (var page in pages) {
            // Delete timers
            final timers = await (database.select(database.timer)
                  ..where((t) => t.pageId.equals(page.id)))
                .get();
            for (var timer in timers) {
              if (timer.positionId != null) {
                await (database.delete(database.position)
                      ..where((t) => t.id.equals(timer.positionId!)))
                    .go();
              }
              await (database.delete(database.timer)
                    ..where((t) => t.id.equals(timer.id)))
                  .go();
            }
            // Delete images
            final pImages = await (database.select(database.images)
                  ..where((t) => t.pageId.equals(page.id)))
                .get();
            for (var img in pImages) {
              if (img.positionId != null) {
                await (database.delete(database.position)
                      ..where((t) => t.id.equals(img.positionId!)))
                    .go();
              }
              await (database.delete(database.images)
                    ..where((t) => t.id.equals(img.id)))
                  .go();
            }

            if (page.sectionPositionId != null) {
              await (database.delete(database.position)
                    ..where((t) => t.id.equals(page.sectionPositionId!)))
                  .go();
            }
            await (database.delete(database.page)
                  ..where((t) => t.id.equals(page.id)))
                .go();
          }
          await (database.delete(database.flow)
                ..where((t) => t.id.equals(flow.id)))
              .go();
        }

        // Finally delete the event itself
        await (database.delete(database.event)
              ..where((t) => t.id.equals(event.id)))
            .go();
      });

      // 2. Delete folders
      final supportDir = await getApplicationSupportDirectory();
      final imagesDir = Directory(
          p.join(supportDir.path, 'YiHuaTimer', 'images', '${event.id}'));
      final schoolsDir = Directory(
          p.join(supportDir.path, 'YiHuaTimer', 'schools', '${event.id}'));

      if (await imagesDir.exists()) await imagesDir.delete(recursive: true);
      if (await schoolsDir.exists()) await schoolsDir.delete(recursive: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('赛事 "${event.eventName}" 已删除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  Widget _buildEventCard(EventData event) {
    final dateStr = event.startDate != null
        ? DateFormat('yyyy-MM-dd').format(event.startDate!)
        : '无日期';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailsPage(event: event),
              ),
            );
          },
          hoverColor: Colors.purple.withOpacity(0.05),
          splashColor: Colors.purple.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.event_note_rounded,
                        color: Colors.purple.shade600,
                        size: 24,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: '删除赛事',
                          child: InkWell(
                            onTap: () => _deleteEvent(event),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red.shade400,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.grey.shade300,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.eventName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            height: 1.2,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 40, 40, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '已保存赛事',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '查看和管理您保存的辩论赛事',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('导入功能暂未实现')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                          side: const BorderSide(
                              color: Color(0xFF4F46E5), width: 1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.file_upload_outlined, size: 18),
                        label: const Text('导入'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('导出功能暂未实现')),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon:
                            const Icon(Icons.file_download_outlined, size: 18),
                        label: const Text('导出'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<List<EventData>>(
            stream: database.select(database.event).watch(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('加载失败: ${snapshot.error}')),
                );
              }

              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      '暂无赛事，去创建一个吧！',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    mainAxisExtent: 180,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (content, index) {
                      return _buildEventCard(events[index]);
                    },
                    childCount: events.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
