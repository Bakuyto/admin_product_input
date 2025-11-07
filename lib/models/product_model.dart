import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // ← ADD
import 'package:http/http.dart' as http;
import 'package:my_flutter_app/models/pub_var.dart' as pub_var;
import 'package:generate_tree/treeNode.dart';

class ProductModel extends ChangeNotifier {
  // ← CHANGE
  List<dynamic> products = [];
  bool loading = true;
  int currentPage = 1;
  int perPage = 20;
  int totalPages = 1;
  String searchQuery = '';
  String? sortColumn = 'name';
  bool sortAscending = true;

  // For edit/add product
  String name = '';
  String sku = '';
  double price = 0.0;
  int stockQuantity = 0;
  String description = '';
  List<int> selectedCategoryIds = [];
  List<Map<String, dynamic>> checkedList = [];
  List<TreeNode> treeListData = [];
  bool loadingCategories = false;
  Uint8List? mainImageBytes;
  String? mainImageBase64;
  List<Uint8List> subImageBytes = [];
  List<String> subImagesBase64 = [];

  Future<void> fetchProducts([int? page]) async {
    final p = page ?? currentPage;
    if (!loading) loading = true;

    try {
      final uri = Uri.parse(
        '${pub_var.apiBase}get_products.php?page=$p&per_page=$perPage&search=$searchQuery',
      );
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final fetchedProducts = (data['data'] as List?) ?? [];

        products = fetchedProducts;
        currentPage = (data['page'] as int?) ?? p;
        perPage = (data['per_page'] as int?) ?? perPage;
        totalPages = (data['total_pages'] as int?) ?? 1;
        loading = false;
        _sortProducts();
        notifyListeners(); // ← ADD
      } else {
        throw Exception('Failed to load products (${res.statusCode})');
      }
    } catch (e) {
      loading = false;
      rethrow;
    }
  }

  Future<void> loadCategories() async {
    loadingCategories = true;
    notifyListeners(); // ← Show loading

    try {
      final res = await http.get(
        Uri.parse("${pub_var.apiBase}get_categories.php"),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // API returns categories directly as array, no success field
        if (data is List) {
          treeListData = _buildTree(data);
        } else if (data is Map && data.containsKey('categories')) {
          treeListData = _buildTree(data['categories'] ?? []);
        } else {
          treeListData = [];
        }
      } else {
        treeListData = [];
      }
    } catch (e) {
      if (kDebugMode) debugPrint('loadCategories error: $e');
      treeListData = [];
    } finally {
      loadingCategories = false;
      notifyListeners(); // ← CRITICAL: Rebuild tree
    }
  }

  Future<void> addCategory(String name, [int parentId = 0]) async {
    final res = await http.post(
      Uri.parse("${pub_var.apiBase}add_category.php"),
      body: {'name': name, 'parent_id': parentId.toString()},
    );
    final data = jsonDecode(res.body);
    if (!data['success']) throw Exception(data['message']);
    await loadCategories(); // ← Rebuild tree
  }

  Future<void> editCategory(int id, String name) async {
    final res = await http.post(
      Uri.parse("${pub_var.apiBase}edit_category.php"),
      body: {'id': id.toString(), 'name': name},
    );
    final data = jsonDecode(res.body);
    if (!data['success']) throw Exception(data['message']);
    await loadCategories(); // ← Rebuild tree
  }

  List<TreeNode> _buildTree(List<dynamic> cats, {int parentId = 0, int depth = 0}) {
    final out = <TreeNode>[];
    for (final c in cats) {
      final id = int.tryParse(c['id'].toString()) ?? 0;
      final subs = c['subcategories'] as List<dynamic>? ?? [];
      final indent = '  ' * depth;
      final prefix = depth > 0 ? '- ' : '';
      final title = '$indent$prefix${c['name'] ?? ''}';
      out.add(TreeNode(
        id: id,
        title: title,
        children: subs.isNotEmpty ? _buildTree(subs, parentId: id, depth: depth + 1) : [],
        checked: false,
        show: false, // Hide all categories initially, let user expand manually
        pid: parentId,
        commonID: 0,
      ));
    }
    return out;
  }

  void _sortProducts() {
    if (sortColumn == null) return;

    products.sort((a, b) {
      final aValue = a[sortColumn];
      final bValue = b[sortColumn];

      final comparison = switch (sortColumn) {
        'price' =>
          (double.tryParse(aValue?.toString() ?? '0') ?? 0.0).compareTo(
            double.tryParse(bValue?.toString() ?? '0') ?? 0.0,
          ),
        _ => (aValue?.toString() ?? '').compareTo(bValue?.toString() ?? ''),
      };

      return sortAscending ? comparison : -comparison;
    });
  }

  void onSort(String columnName) {
    if (sortColumn == columnName) {
      sortAscending = !sortAscending;
    } else {
      sortColumn = columnName;
      sortAscending = true;
    }
    _sortProducts();
    notifyListeners(); // ← ADD
  }

  void onPerPageChanged(int? v) {
    if (v == null || v == perPage) return;
    perPage = v;
    currentPage = 1;
    fetchProducts(1);
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    fetchProducts(1);
  }

  Future<Map<String, dynamic>> deleteProduct(int id) async {
    final res = await http.delete(
      Uri.parse("${pub_var.apiBase}delete_product.php?id=$id"),
    );
    final data = jsonDecode(res.body);
    return data;
  }

  Future<Map<String, dynamic>> updateProduct(
    int id,
    String name,
    String sku,
    double price,
    int stockQuantity,
    List<int> categoryIds,
    String description,
    Uint8List? mainImageBytes,
    List<Uint8List> subImageBytes,
  ) async {
    final uri = Uri.parse("${pub_var.apiBase}update_product.php");
    final request = http.MultipartRequest('POST', uri);

    request.fields['data'] = jsonEncode({
      "id": id,
      "name": name,
      "sku": sku,
      "price": price,
      "stock_quantity": stockQuantity,
      "category_ids": categoryIds,
      "description": description,
    });

    if (mainImageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'main_image',
          mainImageBytes,
          filename: 'main_image.jpg',
        ),
      );
    }

    for (int i = 0; i < subImageBytes.length; i++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'sub_images[]',
          subImageBytes[i],
          filename: 'sub_image_$i.jpg',
        ),
      );
    }

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    final data = jsonDecode(resp.body);
    return data;
  }

  Future<Map<String, dynamic>> fetchProductDetails(int id) async {
    final res = await http.get(
      Uri.parse("${pub_var.apiBase}get_product.php?id=$id"),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return data['product'] ?? {};
      } else {
        throw Exception(data['message'] ?? "Failed to load product details");
      }
    } else {
      throw Exception("Failed to load product details");
    }
  }

  void removeSubImage(int index) {
    if (index >= 0 && index < subImageBytes.length) {
      subImageBytes.removeAt(index);
      subImagesBase64.removeAt(index);
      notifyListeners(); // ← ADD
    }
  }
}
