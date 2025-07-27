import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8000';
  static String? _token;

  static String? get token => _token;

  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;

  Future<User?> getCurrentUser() async {
    if (_token == null) return null;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      // Sign in with Firebase
      final fb_auth.UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      final fb_auth.User? user = userCredential.user;
      if (user == null) return false;

      // Get Firebase ID token
      final idToken = await user.getIdToken();

      // Call backend firebase-login endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/firebase-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': idToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        return true;
      }
      return false;
    } on fb_auth.FirebaseException catch (e) {
      print('Firebase login error: $e');
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<dynamic> register(String email, String password, String username, String role, String name) async {
    try {
      // Create user with Firebase
      final fb_auth.UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      final fb_auth.User? user = userCredential.user;
      if (user == null) return 'Unknown error';

      // Get Firebase ID token
      final idToken = await user.getIdToken();

      // Call backend firebase-register endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/firebase-register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': idToken,
          'username': username,
          'role': role,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        print('Backend registration error: ${errorData['detail']}');
        return errorData['detail'];
      }
      return 'Unknown backend error';
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('Firebase registration error: Email already in use');
        return 'Email already in use';
      } else {
        print('Firebase registration error: $e');
        return e.message ?? 'Firebase registration error';
      }
    } catch (e) {
      print('Registration error: $e');
      return 'Registration error';
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _token = null;
  }
}
