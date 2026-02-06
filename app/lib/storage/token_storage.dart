import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'access_token';
  static const _roleKey = 'role';
  static const _nameKey = 'name';
  static const _companiesKey = 'companies'; // <--- Nova chave

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

  static Future<void> saveSession({
    required String token,
    required String role,
    String? name,
  }) async {
    await saveToken(token);
    await saveRole(role);
    if (name != null) {
      await saveName(name);
    }
  }

  // --- NOVOS MÉTODOS PARA EMPRESAS ---
  static Future<void> saveCompanies(List<String> companies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_companiesKey, companies);
  }

  static Future<List<String>> getCompanies() async {
    final prefs = await SharedPreferences.getInstance();
    // Retorna lista vazia se não achar nada
    return prefs.getStringList(_companiesKey) ?? [];
  }
  // -----------------------------------

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_companiesKey); // <--- Limpar também
  }
}
