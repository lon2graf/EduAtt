// lib/screens/teacher/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/screens/teacher/home_content_teacher_screen.dart';
import 'package:edu_att/screens/teacher/profile_screen.dart';
import 'package:edu_att/screens/teacher/weekly_report_screen.dart';

class TeacherHomeScreen extends ConsumerStatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  ConsumerState<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends ConsumerState<TeacherHomeScreen> {
  int _selectedIndex = 0;

  // Порядок: Главная → Ведомость → Профиль
  final List<Widget> _widgetOptions = const [
    TeacherHomeContentScreen(),
    TeacherWeeklyReportScreen(), // ← новый экран
    TeacherProfileContentScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        indicatorColor: Colors.white.withOpacity(0.4),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
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
        ],
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
