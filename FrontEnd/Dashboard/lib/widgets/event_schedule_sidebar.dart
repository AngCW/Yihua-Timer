import 'package:flutter/material.dart';

class EventScheduleSidebar extends StatelessWidget {
  const EventScheduleSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventTitle('第n届艺华得赛事1'),
                  const SizedBox(height: 12),
                  _buildScheduleItem('初赛1', '27/02/2026', null),
                  _buildScheduleItem('十六强', '28/02/2026', const Color(0xFFD1FAE5)),
                  _buildScheduleItem('八强', '01/03/2026', const Color(0xFFFEF3C7)),
                  _buildScheduleItem('半决赛', '03/03/2026', const Color(0xFFFED7AA)),
                  _buildScheduleItem('决赛', '05/03/2026', const Color(0xFFFEE2E2)),
                  
                  const SizedBox(height: 28),
                  _buildEventTitle('第n届艺辩论赛事2'),
                  const SizedBox(height: 12),
                  _buildScheduleItem('赛事3', '10/03/2026', null),
                  
                  const SizedBox(height: 28),
                  _buildEventTitle('. . . . . . 赛事4'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildScheduleItem(String stage, String date, Color? backgroundColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            stage,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            date,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

