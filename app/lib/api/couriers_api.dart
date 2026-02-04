import 'api_client.dart';

class CouriersApi {
  final ApiClient client;
  CouriersApi(this.client);

  Future<List<dynamic>> listCouriers() async {
    final res = await client.dio.get('/couriers');
    return (res.data as List);
  }

  Future<void> createCourier({
    required String name,
    required String username,
    required String password,
    required List<String> companies,
  }) async {
    await client.dio.post(
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
