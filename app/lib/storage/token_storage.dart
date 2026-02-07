import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'access_token';
  static const _roleKey = 'role';
  static const _nameKey = 'name';
  static const _companiesKey = 'companies';

  // --- GETTERS E SETTERS INDIVIDUAIS ---

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  // --- EMPRESAS ---

  static Future<void> saveCompanies(List<String> companies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_companiesKey, companies);
  }

  static Future<List<String>> getCompanies() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_companiesKey) ?? [];
  }

  // --- SESSÃO COMPLETA (LOGIN) ---

  static Future<void> saveSession({
    required String token,
    required String role,
    String? name,
    List<String>? companies,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Salva tudo usando a mesma instância (mais rápido)
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, role);

    if (name != null) {
      await prefs.setString(_nameKey, name);
    }

    if (companies != null) {
      await prefs.setStringList(_companiesKey, companies);
    }
  }

  // --- LIMPEZA (LOGOUT) ---

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // --- TUTORIAL / ONBOARDING ---

  static const _onboardingKey = 'onboarding_seen';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
}
