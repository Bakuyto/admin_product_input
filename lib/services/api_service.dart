import 'package:flutter/material.dart';

// Base service for handling API calls
class ApiService {
  final String baseUrl;
  
  ApiService({required this.baseUrl});

  Future<dynamic> get(String endpoint) async {
    // Implement GET request
    throw UnimplementedError();
  }

  Future<dynamic> post(String endpoint, {dynamic data}) async {
    // Implement POST request
    throw UnimplementedError();
  }

  Future<dynamic> put(String endpoint, {dynamic data}) async {
    // Implement PUT request
    throw UnimplementedError();
  }

  Future<dynamic> delete(String endpoint) async {
    // Implement DELETE request
    throw UnimplementedError();
  }
}