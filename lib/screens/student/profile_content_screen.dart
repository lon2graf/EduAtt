import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/models/student_model.dart';

class ProfileContentScreen extends ConsumerWidget {
  const ProfileContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StudentModel? student = ref.watch(currentStudentProvider);

    // Используем LayoutBuilder, чтобы растянуть градиент на всё пространство
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: constraints.maxHeight, // Растягиваем на всю высоту
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
              color: Colors.white.withOpacity(0.06),
            ), // Вуаль
            child: SafeArea(
              child: Column(
                children: [
                  // --- Шапка профиля ---
                  _buildProfileHeader(student),
                  const SizedBox(height: 20), // Уменьшен отступ
                  // --- Информация о студенте ---
                  Expanded(child: _buildProfileInfo(student)),
                  // --- Кнопка выхода ---
                  _buildLogoutButton(ref),
                  const SizedBox(height: 14), // Уменьшен отступ
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(StudentModel? student) {
    return Padding(
      padding: const EdgeInsets.all(20.0), // Уменьшены отступы
      child: Row(
        children: [
          Container(
            width: 64, // Уменьшена иконка
            height: 64, // Уменьшена иконка
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18), // Светлее фон иконки
              borderRadius: BorderRadius.circular(32), // Круглая иконка
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 0.8,
              ), // Светлее обводка
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 32, // Уменьшена иконка
            ),
          ),
          const SizedBox(width: 14), // Уменьшен отступ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student?.name ?? 'Имя',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24, // Уменьшен шрифт
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  student?.surname ?? 'Фамилия',
                  style: const TextStyle(
                    color: Colors.white60, // Светлее
                    fontSize: 18, // Уменьшен шрифт
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(StudentModel? student) {
    if (student == null) {
      return const Center(
        child: Text(
          'Данные студента недоступны',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 16,
          ), // Светлее, меньше шрифт
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
      ), // Уменьшены отступы
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard('Email', student.email ?? 'Не указан'),
            const SizedBox(height: 14), // Уменьшен отступ
            _buildInfoCard('Логин', student.login ?? 'Не указан'),
            const SizedBox(height: 14), // Уменьшен отступ
            _buildInfoCard('Староста', student.isHeadman ? 'Да' : 'Нет'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14), // Уменьшены отступы
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14), // Светлее фон
        borderRadius: BorderRadius.circular(12), // Уменьшено скругление
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 0.8,
        ), // Светлее обводка
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60, // Светлее
              fontSize: 13, // Уменьшен шрифт
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2), // Уменьшен отступ
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16, // Уменьшен шрифт
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
      ), // Уменьшены отступы
      child: SizedBox(
        width: double.infinity,
        height: 46, // Уменьшена высота
        child: ElevatedButton(
          onPressed: () {
            ref.read(currentStudentProvider.notifier).logout();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700, // Фиолетовый стиль для кнопки
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Уменьшено скругление
            ),
            elevation: 4, // Уменьшена тень
            shadowColor: Colors.black.withOpacity(0.1),
          ),
          child: const Text(
            'Выйти',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ), // Уменьшен шрифт
          ),
        ),
      ),
    );
  }
}
