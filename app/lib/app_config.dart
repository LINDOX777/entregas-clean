class AppConfig {
  // Se estiver no Emulador Android, use "http://10.0.2.2:8000"
  // Se estiver no Web/Desktop, use "http://localhost:8000"
  static const String baseUrl = "http://localhost:8000";

  /// Monta URL absoluta para arquivos (fotos) servidos pelo backend
  static String fileUrl(String path) {
    if (path.isEmpty) return '';
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrl/$clean';
  }
}
