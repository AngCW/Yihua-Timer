import 'package:debate_timer/EventManager/event_manager_page.dart';
import 'package:flutter/material.dart';
import '../widgets/navigation_sidebar.dart';
import '../widgets/recent_events_section.dart';
import '../widgets/create_event_section.dart';
import '../widgets/shortcuts_section.dart';
import '../widgets/event_schedule_sidebar.dart';
import '../widgets/search_bar.dart';
import '../../CreateEvent/create_event_form.dart';
import '../../../Setting/settings_page.dart';
import '../../Timer/timer_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebar(
            selectedIndex: _selectedNavIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedNavIndex = index;
              });
            },
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF3F4F6),
              child: Column(
                children: [
                  if (_selectedNavIndex != 1 && _selectedNavIndex != 4)
                    const SearchBarWidget(),
                  Expanded(
                    child: KeyedSubtree(
                      key: ValueKey(_selectedNavIndex),
                      child: _buildMainContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const EventScheduleSidebar(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedNavIndex) {
      case 0:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecentEventsSection(
                onViewAll: () {
                  setState(() {
                    _selectedNavIndex = 2;
                  });
                },
              ),
              const SizedBox(height: 40),
              const CreateEventSection(),
              const SizedBox(height: 40),
              const ShortcutsSection(),
            ],
          ),
        );
      case 1:
        return const CreateEventPage();

      case 2:
        return const EventManagerPage();
      case 3:
        return const TimerPage();
      case 4:
        return SettingsPage(
          onBack: () {
            setState(() {
              _selectedNavIndex = 0;
            });
          },
        );
      default:
        return const Center(
          child: Text(
            '该功能正在开发中...',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
        );
    }
  }
}
