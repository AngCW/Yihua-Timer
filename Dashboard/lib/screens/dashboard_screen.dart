import 'package:flutter/material.dart';
import '../widgets/navigation_sidebar.dart';
import '../widgets/recent_events_section.dart';
import '../widgets/create_event_section.dart';
import '../widgets/shortcuts_section.dart';
import '../widgets/event_schedule_sidebar.dart';
import '../widgets/search_bar.dart';
import '../widgets/create_event/create_event_form.dart';
import '../../../Setting/lib/settings_page.dart';

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
              color: const Color(0xFFFAFAFA),
              child: Column(
                children: [
                  if (_selectedNavIndex == 0 || _selectedNavIndex == 2)
                    const SearchBarWidget(),
                  Expanded(
                    child: _buildMainContent(),
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
            children: const [
              RecentEventsSection(),
              SizedBox(height: 40),
              CreateEventSection(),
              SizedBox(height: 40),
              ShortcutsSection(),
            ],
          ),
        );
      case 1:
        return const CreateEventPage();
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
