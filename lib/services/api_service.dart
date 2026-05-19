import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 10.0.2.2 = localhost Mac dari emulator Android
  static const String baseUrl = 'http://10.0.2.2:3001';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('username', data['user']['username']);
    }
    return {'statusCode': response.statusCode, ...data};
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
  }

  static Future<List<dynamic>> getCameras() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/cameras'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['cameras'];
    }
    throw Exception('Gagal mengambil data kamera');
  }

  static Future<List<dynamic>> getRecordings({String? camera, String? date, int limit = 50}) async {
    final headers = await getHeaders();
    final params = {
      'limit': limit.toString(),
      if (camera != null) 'camera': camera,
      if (date != null) 'date': date,
    };
    final uri = Uri.parse('$baseUrl/api/recordings').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['recordings'];
    }
    throw Exception('Gagal mengambil rekaman');
  }

  static Future<String> getRecordingUrl(String key) async {
    final headers = await getHeaders();
    final uri = Uri.parse('$baseUrl/api/recordings/url').replace(
      queryParameters: {'key': key},
    );
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['url'];
    }
    throw Exception('Gagal generate URL');
  }
}
