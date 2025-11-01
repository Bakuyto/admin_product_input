import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:my_flutter_app/models/pub_var.dart';

// Base controller class for common functionality
abstract class BaseController {
  void init();
  void dispose();
}

// Example controller
class AuthController extends BaseController {
  // Add your state management solution here (e.g., ChangeNotifier, GetX, Bloc)

  @override
  void init() {
    // Initialize controller
  }

  @override
  void dispose() {
    // Clean up resources
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
     final url = Uri.parse("${apiBase}login.php"); // Adjust the URL to your server
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return {'success': true, 'user': data['user']};
        } else {
          return {'success': false, 'message': data['message']};
        }
      } else {
        return {'success': false, 'message': 'Server error'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<void> logout() async {
    // Implement logout logic
  }
}
