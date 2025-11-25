import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:edu_att/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // Обязательно для MethodChannel

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Сквозной тест подачи и проверки заявки', () {
    testWidgets('Сценарий: Навигация и заполнение формы входа студента', (
      WidgetTester tester,
    ) async {
      // 1. ЗАГЛУШКА для Shared Preferences
      SharedPreferences.setMockInitialValues({});

      // 2. ЗАГЛУШКА для App Links (Методы)
      const MethodChannel(
        'com.llfbandit.app_links/methods',
      ).setMockMethodCallHandler((MethodCall methodCall) async {
        return null;
      });

      // 3. НОВАЯ ЗАГЛУШКА для App Links (События - Events)
      // Это уберет ошибку "MissingPluginException ... /events"
      const MethodChannel(
        'com.llfbandit.app_links/events',
      ).setMockMethodCallHandler((MethodCall methodCall) async {
        return null;
      });

      // 4. Запуск приложения
      app.main();
      await tester.pumpAndSettle();

      // 5. Поиск кнопки "Вход студента"
      final studentLoginText = find.text('Вход студента');

      // Ждем, чтобы UI точно отрисовался
      await tester.pump(const Duration(seconds: 1));

      expect(studentLoginText, findsOneWidget);
      await tester.tap(studentLoginText);
      await tester.pumpAndSettle();

      // 6. Заполнение полей
      final institutionField = find.widgetWithText(
        TextField,
        'ID образовательной организации',
      );
      await tester.enterText(institutionField, 'university-01');
      await tester.pump(const Duration(milliseconds: 100));

      final emailField = find.widgetWithText(TextField, 'Email');
      await tester.enterText(emailField, 'student@example.com');
      await tester.pump(const Duration(milliseconds: 100));

      final passwordField = find.widgetWithText(TextField, 'Пароль');
      await tester.enterText(passwordField, 'securePass123');
      await tester.pump(const Duration(milliseconds: 100));

      // 7. Нажатие кнопки "Войти"
      final loginButton = find.text('Войти');
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);

      print('Тест нажал кнопку Войти, ждем реакцию...');

      // Ждем пару секунд (эмуляция запроса к сети)
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
