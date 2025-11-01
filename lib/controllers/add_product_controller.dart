import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:html_editor_enhanced/html_editor.dart';

import 'package:generate_tree/treeNode.dart';
import 'package:my_flutter_app/models/add_product_model.dart';
import 'package:my_flutter_app/models/pub_var.dart';

class AddProductController extends ChangeNotifier {
  final AddProductModel _model = AddProductModel();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final HtmlEditorController htmlController = HtmlEditorController();

  AddProductModel get model => _model;

  void init() {
    loadCategories();
    _setupListeners();
  }

  void _setupListeners() {
    nameController.addListener(() => _model.name = nameController.text);
    skuController.addListener(() => _model.sku = skuController.text);
    priceController.addListener(() {
      double parsed = double.tryParse(priceController.text) ?? 0.0;
      _model.price = parsed.isFinite ? parsed : 0.0;
    });
    stockController.addListener(
      () => _model.stockQuantity = int.tryParse(stockController.text) ?? 0,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    skuController.dispose();
    priceController.dispose();
    stockController.dispose();
    htmlController.clear();
    super.dispose();
  }

  // ────────────────────────────────────────────────
  // CATEGORY OPERATIONS
  // ────────────────────────────────────────────────
  Future<void> loadCategories() async {
    _model.loadingCategories = true;
    notifyListeners();

    try {
      await _model.loadCategories();
    } catch (e) {
      debugPrint('Load categories error: $e');
      rethrow;
    } finally {
      _model.loadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(String name, [int parentId = 0]) async {
    await _model.addCategory(name, parentId);
    await loadCategories();
  }

  Future<void> editCategory(int id, String name) async {
    await _model.editCategory(id, name);
    await loadCategories();
  }

  void updateCheckedCategories(TreeNode node, bool isChecked, int commonID) {
    final nodeMap = {'id': node.id, 'value': node.title};
    if (isChecked) {
      if (!_model.checkedList.any((m) => m['id'] == node.id)) {
        _model.checkedList.add(nodeMap);
      }
    } else {
      _model.checkedList.removeWhere((m) => m['id'] == node.id);
    }

    final Set<int> selectedIds = {};
    for (final checkedNode in _model.checkedList) {
      int id = (checkedNode['id'] as num).toInt();
      selectedIds.add(id);

      TreeNode? current = _findNode(_model.treeListData, id);
      while (current != null && current.pid != 0) {
        selectedIds.add(current.pid);
        current = _findNode(_model.treeListData, current.pid);
      }
    }

    _model.selectedCategoryIds = selectedIds.toList()..sort();
    notifyListeners();
  }

  TreeNode? _findNode(List<TreeNode> nodes, int id) {
    for (final n in nodes) {
      if (n.id == id) return n;
      final found = _findNode(n.children, id);
      if (found != null) return found;
    }
    return null;
  }

  // ────────────────────────────────────────────────
  // IMAGE PICKING
  // ────────────────────────────────────────────────
  Future<void> pickMainImage({required bool fromCamera}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      _model.mainImageBytes = bytes;
      _model.mainImageBase64 = base64Encode(bytes);
      notifyListeners();
    }
  }

  Future<void> pickSubImages({required bool fromCamera}) async {
    final picker = ImagePicker();
    if (fromCamera) {
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        _model.subImageBytes.add(bytes);
        _model.subImagesBase64.add(base64Encode(bytes));
        notifyListeners();
      }
    } else {
      final list = await picker.pickMultiImage(imageQuality: 85);
      for (final img in list) {
        final bytes = await img.readAsBytes();
        _model.subImageBytes.add(bytes);
        _model.subImagesBase64.add(base64Encode(bytes));
      }
      notifyListeners();
    }
  }

  void removeSubImage(int index) {
    _model.removeSubImage(index);
    notifyListeners();
  }

  // ────────────────────────────────────────────────
  // DIALOGS
  // ────────────────────────────────────────────────
  void openAddCategoryDialog(BuildContext context, {int parentId = 0}) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(parentId == 0 ? 'Add Main Category' : 'Add Subcategory'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: ctrl.text.trim().isEmpty
                ? null
                : () async {
                    final name = ctrl.text.trim();
                    Navigator.pop(context);
                    await addCategory(name, parentId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Added: $name')));
                    }
                  },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void openEditCategoryDialog(
    BuildContext context, {
    required int id,
    required String currentName,
  }) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: ctrl.text.trim().isEmpty
                ? null
                : () async {
                    final name = ctrl.text.trim();
                    Navigator.pop(context);
                    await editCategory(id, name);
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Updated: $name')));
                    }
                  },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // SAVE PRODUCT – FULLY WORKING
  // ────────────────────────────────────────────────
  Future<void> saveProduct(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      _showSnack(context, 'Fill all required fields.', error: true);
      return;
    }

    final desc = (await htmlController.getText())?.trim() ?? '';
    if (desc.isEmpty) {
      _showSnack(context, 'Description is required.', error: true);
      return;
    }

    if (_model.mainImageBytes == null) {
      _showSnack(context, 'Main image is required.', error: true);
      return;
    }

    if (_model.selectedCategoryIds.isEmpty) {
      _showSnack(context, 'Select at least one category.', error: true);
      return;
    }

    // ── Build JSON string (exact same structure PHP expects)
    final dataMap = {
      "name": _model.name.trim(),
      "sku": _model.sku.trim(),
      "price": _model.price,
      "stock_quantity": _model.stockQuantity,
      "category_ids": _model.selectedCategoryIds,
      "description": desc,
    };
    final jsonString = jsonEncode(dataMap);
    debugPrint('Sending JSON: $jsonString');

    // ── Multipart request
    final request = http.MultipartRequest(
      'POST',
      Uri.parse("${apiBase}add_product.php"),
    );

    // 1. JSON goes in a normal POST field called **data**
    request.fields['data'] = jsonString;

    // 2. Main image
    request.files.add(
      http.MultipartFile.fromBytes(
        'main_image',
        _model.mainImageBytes!,
        filename: 'main_image.jpg',
      ),
    );

    // 3. Sub-images (optional)
    for (int i = 0; i < _model.subImageBytes.length; i++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'sub_images[]',
          _model.subImageBytes[i],
          filename: 'sub_image_$i.jpg',
        ),
      );
    }

    // ── Send
    try {
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      debugPrint('Response: ${resp.body}');

      final jsonResp = jsonDecode(resp.body);
      if (jsonResp['success'] == true) {
        _showSnack(context, jsonResp['message'] ?? 'Saved!', error: false);
        _resetForm();
        if (Navigator.canPop(context)) Navigator.pop(context, true);
      } else {
        throw jsonResp['message'] ?? 'Failed';
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      _showSnack(context, 'Failed: $e', error: true);
    }
  }

  void _showSnack(BuildContext ctx, String msg, {required bool error}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _resetForm() {
    _model.reset();
    nameController.clear();
    skuController.clear();
    priceController.clear();
    stockController.clear();
    htmlController.clear();
    notifyListeners();
  }
}
