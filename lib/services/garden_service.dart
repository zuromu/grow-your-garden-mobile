import 'dart:convert';

import 'package:http/http.dart' as http;

class GardenService {
  // Change this if the Django backend has another address.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://william-jesiel-growyourgarden.pws.cs.ui.ac.id',
  );

  static Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');

    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getPosts(String filter) async {
    final data = await _get('/garden/api/posts/?filter=$filter');

    return (data['posts'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<Map<String, dynamic>> getOverview() {
    return _get('/garden/api/overview/');
  }
}
