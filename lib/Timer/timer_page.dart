import 'package:flutter/material.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
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
          hoverColor: Colors.blue.withOpacity(0.05),
          splashColor: Colors.blue.withOpacity(0.1),
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
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        color: Colors.blue.shade600,
                        size: 24,
                      ),
                    ),
                    Icon(
                      Icons.more_horiz_rounded,
                      color: Colors.grey.shade400,
                      size: 20,
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
                          Icons.calendar_today_rounded,
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
      backgroundColor: const Color(0xFFF9FAFB), // Light grey background
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 40, 40, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '计时器',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '管理您的比赛计时配置',
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
