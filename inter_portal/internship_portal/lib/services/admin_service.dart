import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AdminService {
  static const String baseUrl = 'http://localhost:8000';

  Future<List<dynamic>> getInterneeProgress() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/internees/progress'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data;
      }
      return [];
    } catch (e) {
      print('Error getting internee progress: $e');
      return [];
    }
  }
}
