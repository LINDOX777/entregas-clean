import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  static Future<AuthApi> build() async {
    final client = await ApiClient.create();
    return AuthApi(client);
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _dio.post(
      "/auth/login",
      data: {"username": username, "password": password},
    );
    return Map<String, dynamic>.from(res.data);
  }

  // ✅ backend novo
  Future<List<Map<String, dynamic>>> listCouriers() async {
    final res = await _dio.get("/users/couriers");
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<Map<String, dynamic>> createCourier({
    required String name,
    required String username,
    required String password,
  }) async {
    final res = await _dio.post(
      "/users/couriers",
      data: {"name": name, "username": username, "password": password},
    );
  }
}
