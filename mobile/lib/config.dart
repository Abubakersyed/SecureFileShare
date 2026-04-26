import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppConfig {
  static const _storage = FlutterSecureStorage();
  static const String _key = "server_url";
  static const String defaultUrl = "http://192.168.0.4:8000";

  static Future<String> getBaseUrl() async {
    final saved = await _storage.read(key: _key);
    return saved ?? defaultUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    await _storage.write(key: _key, value: url);
  }
}