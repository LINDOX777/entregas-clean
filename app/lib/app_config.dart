import 'config.dart';

class AppConfig {
  static const String baseUrl = Config.baseUrl;

  /// Monta URL absoluta para arquivos (fotos) servidos pelo backend
  /// Ex: uploads/abc.jpg  -> http://localhost:8000/uploads/abc.jpg
  static String fileUrl(String path) {
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrl/$clean';
  }
}
