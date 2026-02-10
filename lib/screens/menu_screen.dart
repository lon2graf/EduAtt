import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем текущую тему
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // backgroundColor подтянется автоматически из theme.scaffoldBackgroundColor
      body: Center(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Логотип — теперь адаптивный
              Text(
                'EduAtt',
                style: TextStyle(
                  // В темной теме — белый, в светлой — основной фиолетовый
                  color: isDark ? Colors.white : colorScheme.primary,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.6,
                  shadows: [
                    Shadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // Кнопка "Студент"
              _buildMenuButton(
                context,
                icon: Icons.school_rounded,
                title: 'Вход студента',
                onPressed: () => context.go('/login_student'),
              ),
              const SizedBox(height: 20),

              // Кнопка "Преподаватель"
              _buildMenuButton(
                context,
                icon: Icons.person_rounded,
                title: 'Вход преподавателя',
                onPressed: () => context.go('/login_teacher'),
              ),
            ],
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 360 ? 280.0 : screenWidth * 0.85;

    return SizedBox(
      width: maxWidth,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.fade,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          // Используем цвета из ColorScheme
          backgroundColor: colorScheme.primary, // Фиолетовый фон
          foregroundColor: colorScheme.onPrimary, // Белый текст на фиолетовом
          elevation: 4,
          shadowColor: colorScheme.shadow.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
