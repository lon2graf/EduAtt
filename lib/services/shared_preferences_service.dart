import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _userTypeKey = 'user_type';
  static const String _studentLoginKey = 'student_login';
  static const String _studentPasswordKey = 'student_password';
  static const String _studentInstitutionKey = 'student_institution';
  static const String _teacherLoginKey = 'teacher_login';
  static const String _teacherPasswordKey = 'teacher_password';
  static const String _teacherInstitutionKey = 'teacher_institution';
  static const String _themeKey = 'app_theme_mode';
  static const String _mascotEnabledKey = 'mascot_enabled';

  static Future<SharedPreferences> get _instance async =>
      await SharedPreferences.getInstance();

  // === СТУДЕНТ ===
  static Future<void> saveStudentCredentials({
    required String login,
    required String password,
    required String institutionId,
  }) async {
    final prefs = await _instance;
    await prefs.setString(_studentLoginKey, login);
    await prefs.setString(_studentPasswordKey, password);
    await prefs.setString(_studentInstitutionKey, institutionId);
    await prefs.setString(_userTypeKey, 'student');
  }

  static Future<Map<String, String>?> getStudentCredentials() async {
    final prefs = await _instance;
    final login = prefs.getString(_studentLoginKey);
    final password = prefs.getString(_studentPasswordKey);
    final institutionId = prefs.getString(_studentInstitutionKey);

    if (login != null && password != null && institutionId != null) {
      return {
        'login': login,
        'password': password,
        'institutionId': institutionId,
      };
    }
    return null;
  }

  // === ПРЕПОДАВАТЕЛЬ ===
  static Future<void> saveTeacherCredentials({
    required String login,
    required String password,
    required String institutionId,
  }) async {
    final prefs = await _instance;
    await prefs.setString(_teacherLoginKey, login);
    await prefs.setString(_teacherPasswordKey, password);
    await prefs.setString(_teacherInstitutionKey, institutionId);
    await prefs.setString(_userTypeKey, 'teacher');
  }

  static Future<Map<String, String>?> getTeacherCredentials() async {
    final prefs = await _instance;
    final login = prefs.getString(_teacherLoginKey);
    final password = prefs.getString(_teacherPasswordKey);
    final institutionId = prefs.getString(_teacherInstitutionKey);

    if (login != null && password != null && institutionId != null) {
      return {
        'login': login,
        'password': password,
        'institutionId': institutionId,
      };
    }
    return null;
  }

  static Future<void> saveTheme(String themeValue) async {
    final prefs = await _instance;
    await prefs.setString(_themeKey, themeValue);
  }

  /// Получение сохраненной темы
  static Future<String?> getTheme() async {
    final prefs = await _instance;
    return prefs.getString(_themeKey);
  }

  // === ОБЩИЕ МЕТОДЫ ===
  static Future<String?> getUserType() async {
    final prefs = await _instance;
    return prefs.getString(_userTypeKey);
  }

  static Future<void> clearAllData() async {
    final prefs = await _instance;
    await prefs.remove(_studentLoginKey);
    await prefs.remove(_studentPasswordKey);
    await prefs.remove(_studentInstitutionKey);
    await prefs.remove(_teacherLoginKey);
    await prefs.remove(_teacherPasswordKey);
    await prefs.remove(_teacherInstitutionKey);
    await prefs.remove(_userTypeKey);
  }

  static Future<bool> hasSavedSession() async {
    final userType = await getUserType();
    if (userType == 'student') {
      return await getStudentCredentials() != null;
    } else if (userType == 'teacher') {
      return await getTeacherCredentials() != null;
    }
    return false;
  }

  static Future<void> setMascotEnabled(bool enabled) async {
    final prefs = await _instance;
    await prefs.setBool(_mascotEnabledKey, enabled);
  }

  // Чтение настройки (по умолчанию true)
  static Future<bool> getMascotEnabled() async {
    final prefs = await _instance;
    return prefs.getBool(_mascotEnabledKey) ?? true;
  }
}
