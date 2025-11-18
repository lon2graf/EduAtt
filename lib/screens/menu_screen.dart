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
                    context.go('/login');
                  },
                ),
                const SizedBox(height: 20), // Уменьшено с 32 → 20
                // Кнопка "Преподаватель"
                _buildMenuButton(
                  context,
                  icon: Icons.person_rounded,
                  title: 'Вход преподавателя',
                  onPressed: () {
                    // context.go('/login/teacher');
                  },
                ),
                // Ссылка "Продолжить без организации" — удалена
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
    return SizedBox(
      width: 260, // Уменьшено с 300 → 260
      height: 60, // Уменьшено с 72 → 60
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 26, // Уменьшено с 32 → 26
          color: Colors.white,
        ),
        label: Text(
          title,
          style: TextStyle(
            fontSize: 18, // Уменьшено с 20 → 18
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(
            0.12,
          ), // Уменьшена прозрачность фона
          foregroundColor: Colors.white,
          elevation: 6, // Уменьшена тень
          shadowColor: Colors.black.withOpacity(0.12), // Уменьшена тень
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Уменьшено скругление
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ), // Уменьшены отступы
          side: BorderSide(
            color: Colors.white.withOpacity(0.15), // Тонкая обводка
            width: 0.8, // Уже
          ),
        ),
      ),
    );
  }
}
