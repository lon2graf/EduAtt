import 'package:flutter/material.dart';

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
              Color(0xFF5A00FF), // яркий фиолетовый
              Color(0xFF0078FF), // насыщенный синий
              Color(0xFF00C6FF), // голубой оттенок
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          // полупрозрачная вуаль для читаемости контента
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.15)),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'EduAtt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 60),
                _buildMenuButton(
                  context,
                  icon: Icons.school_rounded,
                  title: 'Войти как студент',
                  onPressed: () {
                    // context.go('/login/student');
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuButton(
                  context,
                  icon: Icons.person_rounded,
                  title: 'Войти как преподаватель',
                  onPressed: () {
                    // context.go('/login/teacher');
                  },
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () {
                    // context.go('/offline');
                  },
                  child: const Text(
                    'Продолжить без образовательной организации',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
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
    return SizedBox(
      width: 280,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 26),
        label: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepPurple,
          elevation: 10,
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
