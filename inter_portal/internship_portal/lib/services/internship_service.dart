import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/internship.dart';
import 'auth_service.dart';

class InternshipService {
  static const String baseUrl = 'http://localhost:8000';

  Future<List<Internship>> getAllInternships() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/internships/all'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Internship.fromJson(json)).toList();
      } else {
        print('Failed to load internships: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting all internships: $e');
      return [];
    }
  }

  Future<List<Internship>> getAvailableInternships() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/internships/available'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Internship.fromJson(json)).toList();
      } else {
        print('Failed to load available internships: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting available internships: $e');
      return [];
    }
  }

  Future<Internship?> createInternship(String title, String description, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/internships/'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        return Internship.fromJson(json.decode(response.body));
      } else {
        print('Failed to create internship: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating internship: $e');
      return null;
    }
  }

  Future<bool> updateInternshipStatus(int internshipId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/internships/$internshipId/status'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': status}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating internship status: $e');
      return false;
    }
  }

  Future<String> applyForInternship(int internshipId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/internships/$internshipId/apply'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return "success";
      } else if (response.statusCode == 400 && response.body.contains("Already applied")) {
        return "already_applied";
      } else {
        print('Failed to apply for internship: ${response.statusCode} - ${response.body}');
        return "failure";
      }
    } catch (e) {
      print('Error applying for internship: $e');
      return "failure";
    }
  }

  Future<String> submitInternshipApplication({
    required int internshipId,
    required String name,
    required String universityName,
    required String degree,
    required String semester,
    required dynamic resumeFile, // dynamic to support web and mobile
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/internships/$internshipId/apply_with_details'),
      );
      request.headers['Authorization'] = 'Bearer ${AuthService.token}';

      request.fields['name'] = name;
      request.fields['university_name'] = universityName;
      request.fields['degree'] = degree;
      request.fields['semester'] = semester;

      if (kIsWeb) {
        // For web, resumeFile is a html.File
        final reader = html.FileReader();
        final completer = Completer<Uint8List>();
        reader.readAsArrayBuffer(resumeFile);
        reader.onLoadEnd.listen((event) {
          completer.complete(reader.result as Uint8List);
        });
        final bytes = await completer.future;

        final multipartFile = http.MultipartFile.fromBytes(
          'resume',
          bytes,
          filename: resumeFile.name,
          contentType: MediaType('application', 'pdf'),
        );
        request.files.add(multipartFile);
      } else {
        // For mobile, resumeFile is a File
        request.files.add(
          await http.MultipartFile.fromPath(
            'resume',
            resumeFile.path,
            contentType: MediaType('application', 'pdf'),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return "success";
      } else if (response.statusCode == 400 && response.body.contains("Already applied")) {
        return "already_applied";
      } else {
        print('Failed to submit internship application: ${response.statusCode} - ${response.body}');
        return "failure";
      }
    } catch (e) {
      print('Error submitting internship application: $e');
      return "failure";
    }
  }

  Future<bool> updateInternship(int internshipId, String title, String description, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/internships/$internshipId'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'status': status,
        }),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update internship: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating internship: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> deleteInternship(int internshipId) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/internships/$internshipId'),
      headers: {
        'Authorization': 'Bearer ${AuthService.token}',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Internship not found');
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to delete internship');
    }
  } catch (e) {
    print('Error deleting internship: $e');
    rethrow;
  }
}

  Future<List<Map<String, dynamic>>> getApplications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/applications'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('Failed to get applications: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting applications: $e');
      return [];
    }
  }

  Future<bool> updateApplicationStatus(int applicationId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/applications/$applicationId/status'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update application status: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating application status: $e');
      return false;
    }
  }

  Future<bool> assignTask(int taskId, int interneeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/$taskId/assign'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'internee_id': interneeId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to assign task: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error assigning task: $e');
      return false;
    }
  }
}