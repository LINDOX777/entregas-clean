import 'package:dio/dio.dart';
import '../config.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final Dio dio;

  ApiClient._(this.dio);

  static Future<ApiClient> create() async {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
      ),
    );

    return ApiClient._(dio);
  }
}
