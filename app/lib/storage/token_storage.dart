import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyToken = "access_token";
  static const _keyRole = "role";
  static const _keyName = "name";

  static Future<void> saveSession({
    required String token,
    required String role,
    required String name,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyRole, value: role);
    await _storage.write(key: _keyName, value: name);
  }

  static Future<String?> getToken() async => _storage.read(key: _keyToken);
  static Future<String?> getRole() async => _storage.read(key: _keyRole);
  static Future<String?> getName() async => _storage.read(key: _keyName);

  static Future<void> clear() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRole);
    await _storage.delete(key: _keyName);
  }
}
