import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import 'auth_service.dart';

class TaskService {
  static const String baseUrl = 'http://localhost:8000';

  Future<List<Task>> getAllTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/all'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting all tasks: $e');
      return [];
    }
  }

  Future<List<Task>> getAdminTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/admin'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting admin tasks: $e');
      return [];
    }
  }

  Future<List<Task>> getTasks(int internshipId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/internships/$internshipId/tasks'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  Future<Task?> createTask(int internshipId, String title, String description, DateTime? dueDate) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'internship_id': internshipId,
          'title': title,
          'description': description,
          'due_date': dueDate?.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return Task.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error creating task: $e');
      return null;
    }
  }

  Future<bool> submitTask(int taskId, List<int> fileBytes, String fileName) async {
    try {
      var uri = Uri.parse('$baseUrl/tasks/$taskId/submit');
      var request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer ${AuthService.token}';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('Error submitting task: $e');
      return false;
    }
  }

  Future<List<Task>> getInterneeAssignedTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/assigned'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting assigned tasks: $e');
      return [];
    }
  }

  Future<Task?> updateTask(
    int taskId, 
    String title, 
    String description, 
    int internshipId,
    DateTime? dueDate,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'internship_id': internshipId,
          'due_date': dueDate?.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return Task.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error updating task: $e');
      return null;
    }
  }

  Future<bool> updateAssignment(int taskId, int interneeId) async {
    try {
      // First delete any existing assignment
      await http.delete(
        Uri.parse('$baseUrl/task_assignments/$taskId'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );
      
      // Then create new assignment
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/$taskId/assign?internee_id=$interneeId'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating assignment: $e');
      return false;
    }
  }

  Future<bool> deleteTask(int taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  Future<bool> assignTask(int taskId, int interneeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/$taskId/assign?internee_id=$interneeId'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error assigning task: $e');
      return false;
    }
  }
}