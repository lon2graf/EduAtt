import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4A148C), // Глубокий фиолетовый
              Color(0xFF6A1B9A), // Темно-фиолетовый
              Color(0xFF7B1FA2), // Ярче посередине
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06), // Ещё более прозрачный
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Логотип — чуть меньше, но всё ещё выразительно
                Text(
                  'EduAtt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48, // Уменьшено с 56 → 48
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.6, // Уменьшено
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6, // Уменьшено
                        offset: Offset(0, 3), // Уменьшено
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48), // Уменьшено с 80 → 48
                // Кнопка "Студент"
                _buildMenuButton(
                  context,
                  icon: Icons.school_rounded,
                  title: 'Вход студента',
                  onPressed: () {
                    context.go('/login_student');
                  },
                ),
                const SizedBox(height: 20), // Уменьшено с 32 → 20
                // Кнопка "Преподаватель"
                _buildMenuButton(
                  context,
                  icon: Icons.person_rounded,
                  title: 'Вход преподавателя',
                  onPressed: () {
                    context.go('/login_teacher');
                    // context.go('/login/teacher');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Не фиксировано — адаптируем под экран, но не слишком растягиваем
    final maxWidth = screenWidth > 360 ? 280.0 : screenWidth * 0.85;

    return SizedBox(
      width: maxWidth,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24, color: Colors.white),
        label: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.12),
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: Colors.white.withOpacity(0.15), width: 0.8),
        ),
      ),
    );
  }
}
