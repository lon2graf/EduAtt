import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/models/student_model.dart';

class ProfileContentScreen extends ConsumerWidget {
  const ProfileContentScreen({super.key}); // Добавим ключ

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Получаем данные студента из провайдера
    final StudentModel? student = ref.watch(currentStudentProvider);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5A00FF), Color(0xFF0078FF), Color(0xFF00C6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.15)),
        child: SafeArea(
          child: Column(
            children: [
              // --- Шапка профиля ---
              _buildProfileHeader(student),
              const SizedBox(height: 24),
              // --- Информация о студенте ---
              Expanded(child: _buildProfileInfo(student)),
              // --- Кнопка выхода ---
              _buildLogoutButton(ref),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Виджет для шапки профиля (имя, фамилия)
  Widget _buildProfileHeader(StudentModel? student) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          // Иконка профиля (заглушка)
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(35), // Круглая иконка
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student?.name ?? 'Имя',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  student?.surname ?? 'Фамилия',
                  style: const TextStyle(color: Colors.white70, fontSize: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Виджет для отображения информации о студенте
  Widget _buildProfileInfo(StudentModel? student) {
    if (student == null) {
      // Если студент не вошёл, показываем сообщение
      return const Center(
        child: Text(
          'Данные студента недоступны',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Убрали карточку с организацией
            // _buildInfoCard(
            //   'Образовательная организация',
            //   student.institutionId,
            // ),
            // const SizedBox(height: 16),
            // Убрали карточку с группой
            // _buildInfoCard('Группа', student.groupId),
            // const SizedBox(height: 16),
            _buildInfoCard('Email', student.email ?? 'Не указан'),
            const SizedBox(height: 16),
            _buildInfoCard('Логин', student.login ?? 'Не указан'),
            const SizedBox(height: 16),
            _buildInfoCard('Староста', student.isHeadman ? 'Да' : 'Нет'),
            // Добавьте другие поля модели StudentModel, если нужно
          ],
        ),
      ),
    );
  }

  // Вспомогательный виджет для карточки информации
  Widget _buildInfoCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Виджет для кнопки выхода
  Widget _buildLogoutButton(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            // Вызываем метод logout из провайдера
            ref.read(currentStudentProvider.notifier).logout();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Выйти',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
