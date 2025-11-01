import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:generate_tree/treeNode.dart';
import 'package:my_flutter_app/models/pub_var.dart';

class AddProductModel {
  // Form data
  String name = '';
  String sku = '';
  double price = 0.0;
  int stockQuantity = 0;
  String description = '';

  // Images
  Uint8List? mainImageBytes;
  List<Uint8List> subImageBytes = [];
  String? mainImageBase64;
  List<String> subImagesBase64 = [];

  // Categories
  List<TreeNode> treeListData = [];
  List<Map<String, dynamic>> checkedList = [];
  List<int> selectedCategoryIds = [];
  bool loadingCategories = true;

  AddProductModel();

  void reset() {
    name = '';
    sku = '';
    price = 0.0;
    stockQuantity = 0;
    description = '';
    mainImageBytes = null;
    subImageBytes.clear();
    mainImageBase64 = null;
    subImagesBase64.clear();
    checkedList.clear();
    selectedCategoryIds.clear();
  }

  void removeSubImage(int index) {
    if (index >= 0 && index < subImageBytes.length) {
      subImageBytes.removeAt(index);
      subImagesBase64.removeAt(index);
    }
  }

  Future<void> loadCategories() async {
    final res = await http.get(Uri.parse("${apiBase}get_categories.php"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      treeListData = flattenCategories(data);
    } else {
      throw Exception("Failed to load categories");
    }
  }

  List<TreeNode> flattenCategories(
    List<dynamic> cats, {
    int parentId = 0,
    int depth = 0,
  }) {
    final List<TreeNode> out = [];
    for (final c in cats) {
      final id = int.tryParse(c['id'].toString()) ?? 0;
      final subs = c['subcategories'] as List<dynamic>? ?? [];
      final indent = '  ' * depth;
      final prefix = depth > 0 ? '- ' : '';
      final title = '$indent$prefix${c['name'] ?? ''}';
      final node = TreeNode(
        id: id,
        title: title,
        children: subs.isNotEmpty
            ? flattenCategories(subs, parentId: id, depth: depth + 1)
            : [],
        checked: false,
        show: depth == 0,
        pid: parentId,
        commonID: 0,
      );
      out.add(node);
    }
    return out;
  }

  Future<void> addCategory(String name, [int parentId = 0]) async {
    final res = await http.post(
      Uri.parse("${apiBase}add_category.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "parent_id": parentId}),
    );
    final data = jsonDecode(res.body);
    if (data["success"] != true) {
      throw Exception(data['message'] ?? "Failed to add category");
    }
  }

  Future<void> editCategory(int id, String name) async {
    final res = await http.post(
      Uri.parse("${apiBase}edit_category.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": id, "name": name}),
    );
    final data = jsonDecode(res.body);
    if (data["success"] != true) {
      throw Exception(data['message'] ?? "Failed to edit category");
    }
  }
}
