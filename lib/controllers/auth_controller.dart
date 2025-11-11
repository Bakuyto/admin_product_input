import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<Map<String, dynamic>> login(String username, String password, {bool remember = false}) async {
    final url = Uri.parse(
      "${apiBase}login.php",
    ); // Adjust the URL to your server
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Save session data
          await _saveSession(data['user'], remember: remember, savedUsername: remember ? username : null);
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
    // Clear session data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Clear global variables
    userRole = null;
  }

  Future<void> _saveSession(Map<String, dynamic> user, {bool remember = false, String? savedUsername}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user['user_id'].toString());
    await prefs.setString('username', user['username']);
    await prefs.setString('user_role', user['user_role'].toString());
    await prefs.setBool('remember_me', remember);
    if (remember && savedUsername != null) {
      await prefs.setString('saved_username', savedUsername);
    }
  }

  Future<Map<String, dynamic>?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final username = prefs.getString('username');
    final userRoleStr = prefs.getString('user_role');

    if (userId != null && username != null && userRoleStr != null) {
      final user = {
        'user_id': userId,
        'username': username,
        'user_role': userRoleStr,
      };
      // Set global userRole
      userRole = userRoleStr;
      return user;
    }
    return null;
  }

  Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_username');
  }

  Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('remember_me') ?? false;
  }
}
