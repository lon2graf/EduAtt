import 'package:edu_att/screens/student/profile_content_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/services/lessons_attendace_service.dart';
import 'package:edu_att/providers/lesson_attendance_provider.dart';
import 'package:edu_att/screens/student/home_content_screen.dart';
import 'package:edu_att/screens/student/misses_content_screen.dart';
import 'package:edu_att/screens/student/weekle_report_screen.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  int _selectedIndex = 0;

  // Виджеты: 0 — Главная, 1 — Посещаемость, 2 — Ведомость (если староста), 3 — Профиль
  List<Widget> _buildWidgetOptions(bool isHeadman) {
    if (isHeadman) {
      return [
        const HomeContentScreen(),
        const MissesContentScreen(),
        const WeeklyReportScreen(),
        const ProfileContentScreen(),
      ];
    } else {
      return [
        const HomeContentScreen(),
        const MissesContentScreen(),
        const ProfileContentScreen(),
      ];
    }
  }

  List<NavigationDestination> _buildDestinations(bool isHeadman) {
    if (isHeadman) {
      return const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Главная',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_busy_outlined),
          selectedIcon: Icon(Icons.event_busy),
          label: 'Посещаемость',
        ),
        NavigationDestination(
          icon: Icon(Icons.picture_as_pdf_outlined),
          selectedIcon: Icon(Icons.picture_as_pdf),
          label: 'Ведомость',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outlined),
          selectedIcon: Icon(Icons.person),
          label: 'Профиль',
        ),
      ];
    } else {
      return const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Главная',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_busy_outlined),
          selectedIcon: Icon(Icons.event_busy),
          label: 'Посещаемость',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outlined),
          selectedIcon: Icon(Icons.person),
          label: 'Профиль',
        ),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(currentStudentProvider);
    final isHeadman = student?.isHeadman == true;

    // Корректируем индекс, если переключились с/на старосту
    if (isHeadman && _selectedIndex > 3) _selectedIndex = 0;
    if (!isHeadman && _selectedIndex > 2) _selectedIndex = 0;

    final widgetOptions = _buildWidgetOptions(isHeadman);
    final destinations = _buildDestinations(isHeadman);

    return Scaffold(
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        indicatorColor: Colors.white.withOpacity(0.4),
        destinations: destinations,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
