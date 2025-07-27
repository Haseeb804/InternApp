import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'auth_service.dart';

class UserService {
  static const String baseUrl = 'http://localhost:8000';

  Future<List<User>> getAllInternees() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/internees'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting internees: $e');
      return [];
    }
  }
}
