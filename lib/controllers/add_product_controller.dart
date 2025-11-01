import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:camera/camera.dart';
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


  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  bool isCameraInitialized = false;

  AddProductModel get model => _model;

  void init() {
    loadCategories();
    _setupListeners();
  }

  Future<void> initializeCamera() async {
    if (isCameraInitialized) return;
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await cameraController!.initialize();
        isCameraInitialized = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _setupListeners() {
    nameController.addListener(() => _model.name = nameController.text);
    skuController.addListener(() => _model.sku = skuController.text);
    priceController.addListener(
      () => _model.price = double.tryParse(priceController.text) ?? 0.0,
    );
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
    model.loadingCategories = true;
    notifyListeners();
    try {
      await _model.loadCategories();
    } catch (e) {
      debugPrint('Load categories error: $e');
      rethrow;
    } finally {
      model.loadingCategories = false;
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

      // Add all ancestor IDs
      TreeNode? currentNode = _model.treeListData.expand((n) => [n, ...n.children]).firstWhere(
        (n) => n.id == id,
        orElse: () => TreeNode(id: -1, title: '', children: [], checked: false, show: true, pid: 0, commonID: 0),
      );
      while (currentNode != null && currentNode.id != -1) {
        // Assuming parentId is not directly available, we might need to adjust this logic
        // For now, skip ancestor addition as TreeNode doesn't have parentId
        break;
      }
    }

    _model.selectedCategoryIds = selectedIds.toList();
    notifyListeners();
  }



  // ────────────────────────────────────────────────
  // IMAGE PICKING (Gallery + Camera)
  // ────────────────────────────────────────────────
  Future<void> pickMainImage({required bool fromCamera}) async {
    if (fromCamera && isCameraInitialized && cameraController != null) {
      // Use camera package for live preview
      try {
        final XFile image = await cameraController!.takePicture();
        final bytes = await image.readAsBytes();
        _model.mainImageBytes = bytes;
        _model.mainImageBase64 = base64Encode(bytes);
        notifyListeners();
      } catch (e) {
        debugPrint('Camera capture error: $e');
        // Fallback to image picker
        await _pickImageWithPicker(fromCamera: true);
      }
    } else {
      // Use image picker for gallery or fallback
      await _pickImageWithPicker(fromCamera: fromCamera);
    }
  }

  Future<void> _pickImageWithPicker({required bool fromCamera}) async {
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
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        _model.subImageBytes.add(bytes);
        _model.subImagesBase64.add(base64Encode(bytes));
        notifyListeners();
      }
    } else {
      final pickedList = await picker.pickMultiImage();
      for (final img in pickedList) {
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
  // CATEGORY DIALOGS
  // ────────────────────────────────────────────────
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
                      await addCategory(name, parentId);
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
                      await editCategory(id, newName);
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

  // ────────────────────────────────────────────────
  // SAVE PRODUCT
  // ────────────────────────────────────────────────
  Future<void> saveProduct(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      _showSnack(context, 'Please fill in required fields.', error: true);
      return;
    }

    final descHtml = await htmlController.getText();
    _model.description = descHtml;

    if (_model.mainImageBytes == null) {
      _showSnack(context, 'Main image is required.', error: true);
      return;
    }

    final uri = Uri.parse("${apiBase}add_product.php");
    final request = http.MultipartRequest('POST', uri);

    request.fields['data'] = jsonEncode({
      "name": _model.name,
      "sku": _model.sku,
      "price": _model.price,
      "stock_quantity": _model.stockQuantity,
      "category_ids": _model.selectedCategoryIds,
      "description": _model.description,
    });

    request.files.add(
      http.MultipartFile.fromBytes(
        'main_image',
        _model.mainImageBytes!,
        filename: 'main_image.jpg',
      ),
    );

    for (int i = 0; i < _model.subImageBytes.length; i++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'sub_images[]',
          _model.subImageBytes[i],
          filename: 'sub_image_$i.jpg',
        ),
      );
    }

    try {
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      final Map<String, dynamic> jsonResp = jsonDecode(resp.body);

      if (jsonResp['success'] == true) {
        _showSnack(
          context,
          jsonResp['message'] ?? 'Product saved!',
          error: false,
        );
        _resetForm();
        if (Navigator.canPop(context)) Navigator.pop(context, true);
      } else {
        throw jsonResp['message'] ?? 'Unknown error';
      }
    } catch (e) {
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
