import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_flutter_app/models/pub_var.dart';
import '../constants/api_constants.dart';
import '../models/base_model.dart';

class CategoryController {
  Future<BaseModel> addCategory(String name, {int? parentId}) async {
    try {
      final response = await http.post(
        Uri.parse('${apiBase}${ApiConstants.addCategory}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'parent_id': parentId ?? 0}),
      );

      final data = jsonDecode(response.body);
      return BaseModel.fromJson(data);
    } catch (e) {
      return BaseModel(success: false, message: 'Network error: $e');
    }
  }

  Future<BaseModel> editCategory(int id, String name) async {
    try {
      final response = await http.post(
        Uri.parse('${apiBase}${ApiConstants.editCategory}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'name': name}),
      );

      final data = jsonDecode(response.body);
      return BaseModel.fromJson(data);
    } catch (e) {
      return BaseModel(success: false, message: 'Network error: $e');
    }
  }

  Future<BaseModel> deleteCategory(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${apiBase}${ApiConstants.deleteCategory}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );

      final data = jsonDecode(response.body);
      return BaseModel.fromJson(data);
    } catch (e) {
      return BaseModel(success: false, message: 'Network error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${apiBase}${ApiConstants.getCategories}'),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
