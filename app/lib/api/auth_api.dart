import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import 'api_client.dart';

class AuthApi {
  final Dio dio;
  AuthApi(this.dio);

  static Future<AuthApi> build() async {
    final client = await ApiClient.create();
    return AuthApi(client.dio);
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );

    final data = (res.data as Map).cast<String, dynamic>();
    final token = data['access_token'] as String;
    final role = (data['role'] as String?) ?? '';

    await TokenStorage.saveToken(token);
    await TokenStorage.saveRole(role);

    return data;
  }

  Future<void> logout() async {
    await TokenStorage.clear();
  }

  // ✅ backend novo
  Future<List<Map<String, dynamic>>> listCouriers() async {
    final res = await dio.get('/couriers');
    return (res.data as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  // ✅ backend novo + companies obrigatório
  Future<void> createCourier({
    required String name,
    required String username,
    required String password,
    required List<String> companies,
  }) async {
    await dio.post(
      '/couriers',
      data: {
        'name': name,
        'username': username,
        'password': password,
        'companies': companies,
      },
    );
  }
}
