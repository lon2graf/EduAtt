import 'package:edu_att/data/remote/shared_preferences_service.dart';
import 'package:edu_att/mascot/mascot_manager.dart';
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      mascotState: MascotState.greeting,
      title: 'Привет! Я Фрося',
      subtitle:
          'Буду помогать тебе следить за посещаемостью.\nНикаких пропусков мимо меня!',
    ),
    _SlideData(
      mascotState: MascotState.science,
      title: 'Всё под рукой',
      subtitle:
          'Расписание занятий, статус посещаемости и подробная статистика — всё в одном месте.\n\nДля студентов, старост и преподавателей.',
    ),
    _SlideData(
      mascotState: MascotState.success,
      title: 'Готова помочь!',
      subtitle:
          'Выбери способ входа и начнём вместе следить за твоей учёбой. Фрося всегда рядом!',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await SharedPreferencesService.setOnboardingSeen();
    if (mounted) context.go('/');
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Кнопка «Пропустить»
            SizedBox(
              height: 48,
              child: isLast
                  ? null
                  : Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _finish,
                        child: Text(
                          'Пропустить',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
            ),

            // Слайды
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _SlidePage(data: _slides[i]),
              ),
            ),

            // Индикатор точек
            _DotsIndicator(
              count: _slides.length,
              current: _currentPage,
              colorScheme: colorScheme,
            ),

            const SizedBox(height: 28),

            // Кнопка действия
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    isLast ? 'Начать' : 'Далее',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

// ─── Данные слайда ────────────────────────────────────────────────────────────

class _SlideData {
  final MascotState mascotState;
  final String title;
  final String subtitle;

  const _SlideData({
    required this.mascotState,
    required this.title,
    required this.subtitle,
  });
}

// ─── Страница слайда ──────────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _SlideData data;

  const _SlidePage({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EduMascot(state: data.mascotState, height: 200),
          const SizedBox(height: 40),
          Text(
            data.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Индикатор точек ──────────────────────────────────────────────────────────

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int current;
  final ColorScheme colorScheme;

  const _DotsIndicator({
    required this.count,
    required this.current,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? colorScheme.primary : colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
