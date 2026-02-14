import 'package:flutter/material.dart';

class EventManagerPage extends StatefulWidget {
  const EventManagerPage({super.key});

  @override
  State<EventManagerPage> createState() => _EventManagerPageState();
}

class _EventManagerPageState extends State<EventManagerPage> {
  final testGrid = List.generate(15, (index) => index + 1);

  Widget _buildEventCard(int index) {
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
            print("$index grid clicked");
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
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey.shade300,
                      size: 16,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "赛事 $index",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.5,
                      ),
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
                          "27/02/2022 13:00",
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
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisExtent: 180,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              delegate: SliverChildBuilderDelegate(
                (content, index) {
                  final tempGrid = testGrid[index];
                  return _buildEventCard(tempGrid);
                },
                childCount: testGrid.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
