import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String BASE_URL = "http://192.168.0.4:8000";

class ApiService {
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, dynamic>> register(String email, String password) async {
    final res = await http.post(
      Uri.parse("$BASE_URL/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    return jsonDecode(res.body);
  }

  static Future<String?> login(String email, String password) async {
    final res = await http.post(
      Uri.parse("$BASE_URL/auth/login"),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: "username=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}",
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final token = data["access_token"] as String;
      await _storage.write(key: "jwt_token", value: token);
      return token;
    }
    return null;
  }

  static Future<void> logout() async {
    await _storage.delete(key: "jwt_token");
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: "jwt_token");
  }

  static Future<Map<String, dynamic>?> uploadFile({
    required List<int> bytes,
    required String filename,
    required int ttlMinutes,
  }) async {
    final token = await getToken();
    if (token == null) return null;

    final request = http.MultipartRequest("POST", Uri.parse("$BASE_URL/files/upload"))
      ..headers["Authorization"] = "Bearer $token"
      ..fields["ttl_minutes"] = ttlMinutes.toString()
      ..files.add(http.MultipartFile.fromBytes("file", bytes, filename: filename));

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }
}
