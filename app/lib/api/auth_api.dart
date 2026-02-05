import '../storage/token_storage.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  static Future<AuthApi> build() async {
    final client = await ApiClient.create();
    return AuthApi(client);
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _client.dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );

    final data = (res.data as Map).cast<String, dynamic>();

    final token = data['access_token'] as String;
    final role = (data['role'] as String?) ?? '';
    final name = (data['name'] as String?) ?? '';
    final companies = List<String>.from(data['companies'] ?? []);

    await TokenStorage.saveToken(token);
    await TokenStorage.saveRole(role);
    if (name.isNotEmpty) {
      await TokenStorage.saveName(name);
    }
    await TokenStorage.saveCompanies(companies);

    return data;
  }

  Future<List<Map<String, dynamic>>> listCouriers() async {
    final res = await _client.dio.get('/users/couriers');
    final data = List<Map<String, dynamic>>.from(res.data);
    return data;
  }

  Future<void> createCourier({
    required String name,
    required String username,
    required String password,
    required List<String> companies,
  }) async {
    await _client.dio.post(
      '/users/couriers',
      data: {
        'name': name,
        'username': username,
        'password': password,
        'companies': companies,
      },
    );
  }

  Future<void> updateCourierCompanies({
    required int courierId,
    required List<String> companies,
  }) async {
    await _client.dio.patch(
      '/users/couriers/$courierId/companies',
      data: {'companies': companies},
    );
  }
}
