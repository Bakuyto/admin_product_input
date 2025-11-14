// edit_product_controller.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:my_flutter_app/models/pub_var.dart';
import 'package:my_flutter_app/models/product_model.dart';
import 'package:generate_tree/treeNode.dart';

class EditProductController extends ChangeNotifier {
  final int productId;
  final ProductModel model = ProductModel();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController skuController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  late HtmlEditorController htmlController;

  CameraController? cameraController;
  bool isCameraInitialized = false;
  bool isLoading = true;

  String? errorMessage;

  List<TreeNode> treeListData = [];

  EditProductController(this.productId);

  Future<void> init() async {
    try {
      _initControllers();
      // Load categories first so we can map product category IDs to the tree
      await model.loadCategories();
      treeListData = model.treeListData;
      await _initCamera();
      await _loadProduct();
      // After both categories and product are loaded, sync checked list
      _syncCheckedList();
      isLoading = false;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
    }
    notifyListeners();
  }

  void _initControllers() {
    nameController = TextEditingController();
    skuController = TextEditingController();
    priceController = TextEditingController();
    stockController = TextEditingController();
    htmlController = HtmlEditorController();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      cameraController = CameraController(cameras[0], ResolutionPreset.high);
      await cameraController!.initialize();
      isCameraInitialized = true;
    } catch (e) {
      // Camera not available or permission denied, continue without camera
      isCameraInitialized = false;
    }
    notifyListeners();
  }

  // ── LOAD PRODUCT FROM API ──
  Future<void> _loadProduct() async {
    final res = await http.get(
      Uri.parse("${apiBase}get_product.php?id=$productId"),
    );
    if (res.statusCode != 200) throw Exception('Failed to load');

    final data = jsonDecode(res.body);
    if (!data['success']) throw Exception(data['message']);

    final p = data['product'];

    nameController.text = p['name'] ?? '';
    skuController.text = p['sku'] ?? '';
    priceController.text = p['price'].toString();
    stockController.text = p['stock_quantity'].toString();
    htmlController.setText(p['description'] ?? '');
    model.description = p['description'] ?? '';

    // Parse category IDs: API may return a comma-separated string, a JSON array, or null
    final dynamic categoryRaw = p['category_ids'];
    final List<int> catIds = [];
    if (categoryRaw != null) {
      if (categoryRaw is String) {
        catIds.addAll(
          categoryRaw
              .split(',')
              .where((e) => e.isNotEmpty)
              .map((e) => int.tryParse(e) ?? 0)
              .where((v) => v != 0),
        );
      } else if (categoryRaw is List) {
        catIds.addAll(
          categoryRaw
              .map((e) => int.tryParse(e?.toString() ?? '') ?? 0)
              .where((v) => v != 0),
        );
      } else if (categoryRaw is int) {
        catIds.add(categoryRaw);
      } else {
        // try to coerce to string then parse
        final s = categoryRaw.toString();
        if (s.isNotEmpty) {
          catIds.addAll(
            s
                .split(',')
                .where((e) => e.isNotEmpty)
                .map((e) => int.tryParse(e) ?? 0)
                .where((v) => v != 0),
          );
        }
      }
    }
    model.selectedCategoryIds = catIds;

    // If API returned a 'categories' array (objects with id/name) but no category_ids,
    // use that to populate selectedCategoryIds.
    if (model.selectedCategoryIds.isEmpty && p['categories'] != null) {
      try {
        final cats = p['categories'];
        if (cats is List) {
          final fromCats = <int>[];
          for (final c in cats) {
            try {
              final id = int.tryParse(c['id']?.toString() ?? '') ?? 0;
              if (id != 0) fromCats.add(id);
            } catch (_) {}
          }
          if (fromCats.isNotEmpty) model.selectedCategoryIds = fromCats;
        }
      } catch (_) {
        // ignore parsing errors
      }
    }

    // Use the full URLs returned by the API for main and sub images
    final mainImageUrl = p['main_image'];
    if (mainImageUrl != null && mainImageUrl.isNotEmpty) {
      final bytes = await _downloadImage(mainImageUrl);
      model.mainImageBase64 = base64Encode(bytes);
      model.mainImageBytes = bytes;
    }

    final subImages = p['sub_images'] as List<dynamic>? ?? [];
    for (final url in subImages) {
      if (url != null && url.isNotEmpty) {
        final bytes = await _downloadImage(url);
        model.subImagesBase64.add(base64Encode(bytes));
        model.subImageBytes.add(bytes);
      }
    }

    // Removed syncing here — syncing happens after categories are loaded in init().
  }

  Future<Uint8List> _downloadImage(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) return res.bodyBytes;
    throw Exception('Image not found');
  }

  void _syncCheckedList() {
    try {
      // Debug: show what's being compared so we can diagnose mismatches.
      if (kDebugMode) {
        debugPrint(
          'EditProductController: selectedCategoryIds=${model.selectedCategoryIds}',
        );
        final treeIds = model.treeListData.map((e) => e.id).toList();
        debugPrint('EditProductController: treeListData ids=$treeIds');
      }

      // Set checked status on the tree nodes
      for (var node in treeListData) {
        _setCheckedRecursive(node, model.selectedCategoryIds);
      }

      // Update checkedList for consistency
      model.checkedList = _getCheckedNodes(treeListData);

      if (kDebugMode) {
        final checkedIds = model.checkedList.map((e) => e['id']).toList();
        debugPrint('EditProductController: checkedList ids=$checkedIds');
      }
    } catch (e) {
      if (kDebugMode)
        debugPrint('EditProductController: _syncCheckedList error: $e');
    }

    notifyListeners();
  }

  void _setCheckedRecursive(TreeNode node, List<int> selectedIds) {
    node.checked = selectedIds.contains(node.id);
    for (var child in node.children) {
      _setCheckedRecursive(child, selectedIds);
    }
  }

  List<Map<String, dynamic>> _getCheckedNodes(List<TreeNode> nodes) {
    List<Map<String, dynamic>> checked = [];
    for (var node in nodes) {
      if (node.checked) {
        checked.add({'id': node.id, 'value': node.title});
      }
      checked.addAll(_getCheckedNodes(node.children));
    }
    return checked;
  }

  // ── IMAGE PICKERS ──
  Future<void> pickMainImage({required bool fromCamera}) async {
    final picker = ImagePicker();
    final file = fromCamera
        ? await picker.pickImage(source: ImageSource.camera, imageQuality: 85)
        : await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    model.mainImageBytes = bytes;
    model.mainImageBase64 = base64Encode(bytes);
    notifyListeners();
  }

  Future<void> pickSubImages({required bool fromCamera}) async {
    final picker = ImagePicker();
    if (fromCamera) {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        model.subImageBytes.add(bytes);
        model.subImagesBase64.add(base64Encode(bytes));
        notifyListeners();
      }
    } else {
      final pickedList = await picker.pickMultiImage();
      for (final img in pickedList) {
        final bytes = await img.readAsBytes();
        model.subImageBytes.add(bytes);
        model.subImagesBase64.add(base64Encode(bytes));
      }
      notifyListeners();
    }
  }

  void removeSubImage(int i) {
    model.removeSubImage(i);
    notifyListeners();
  }

  void updateCheckedCategories(TreeNode node, bool isChecked, int commonID) {
    // Update the node's checked status
    node.checked = isChecked;

    // Recursively update children if needed
    if (isChecked) {
      _setCheckedRecursiveBool(node, true);
    }

    // Update model's checkedList and selectedCategoryIds
    model.checkedList = _getCheckedNodes(treeListData);
    model.selectedCategoryIds = model.checkedList
        .map((e) => e['id'] as int)
        .toList();

    notifyListeners();
  }

  void _setCheckedRecursiveBool(TreeNode node, bool checked) {
    node.checked = checked;
    for (var child in node.children) {
      _setCheckedRecursiveBool(child, checked);
    }
  }

  // ── CATEGORY DIALOGS ──
  void openAddCategoryDialog(BuildContext context, {int parentId = 0}) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            parentId == 0 ? 'Add Main Category' : 'Add Subcategory',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Category Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: textController.text.trim().isEmpty
                  ? null
                  : () async {
                      final name = textController.text.trim();
                      Navigator.pop(context);
                      await model.addCategory(name, parentId);
                      await model.loadCategories();
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Added: $name")));
                      }
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void openEditCategoryDialog(
    BuildContext context, {
    required int id,
    required String currentName,
  }) {
    final textController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Category',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Category Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: textController.text.trim().isEmpty
                  ? null
                  : () async {
                      final newName = textController.text.trim();
                      Navigator.pop(context);
                      await model.editCategory(id, newName);
                      await model.loadCategories();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Updated: $newName")),
                        );
                      }
                    },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // ── UPDATE PRODUCT ──
  Future<void> updateProduct(BuildContext ctx) async {
    if (!formKey.currentState!.validate()) return;

    model.name = nameController.text.trim();
    model.sku = skuController.text.trim();
    model.price = double.tryParse(priceController.text) ?? 0.0;
    model.stockQuantity = int.tryParse(stockController.text) ?? 0;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse("${apiBase}update_product.php"),
    );

    // PUT wc_id INSIDE data JSON
    request.fields['data'] = jsonEncode({
      "wc_id": productId, // ← THIS IS THE KEY
      "name": model.name,
      "sku": model.sku,
      "price": model.price,
      "stock_quantity": model.stockQuantity,
      "category_ids": model.selectedCategoryIds,
      "description": model.description,
    });

    // Main image
    if (model.mainImageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'main_image',
          model.mainImageBytes!,
          filename: 'main.jpg',
        ),
      );
    }

    // Sub images
    for (int i = 0; i < model.subImageBytes.length; i++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'sub_images[]',
          model.subImageBytes[i],
          filename: 'sub_$i.jpg',
        ),
      );
    }

    try {
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      final json = jsonDecode(resp.body);

      if (json['success'] == true) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(ctx, true);
      } else {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(json['message'] ?? 'Update failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── DELETE PRODUCT ──
  Future<void> deleteProduct(BuildContext ctx) async {
    final res = await http.post(
      Uri.parse("${apiBase}delete_product.php"),
      body: {'wc_id': productId.toString()},
    );
    final json = jsonDecode(res.body);
    if (json['success']) {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(const SnackBar(content: Text('Deleted')));
      Navigator.pop(ctx);
    } else {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text(json['message'] ?? 'Failed')));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    skuController.dispose();
    priceController.dispose();
    stockController.dispose();
    htmlController.clear();
    cameraController?.dispose();
    super.dispose();
  }
}
