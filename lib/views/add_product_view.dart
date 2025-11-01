// ─────────────────────────────────────────────────────────────────────────────
//  add_product_page.dart (With Camera + Gallery Support)
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:generate_tree/generate_tree.dart';
import 'package:generate_tree/treeNode.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:my_flutter_app/controllers/add_product_controller.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  late final AddProductController controller;

  @override
  void initState() {
    super.initState();
    controller = AddProductController()..init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: const _AddProductView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  UI
// ─────────────────────────────────────────────────────────────────────────────
class _AddProductView extends StatefulWidget {
  const _AddProductView();

  @override
  State<_AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<_AddProductView> {

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AddProductController>();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Add New Product'),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _modernCard(
                icon: Icons.inventory_2_outlined,
                title: "Product Details",
                child: _buildProductDetailsCard(controller),
              ),
              _modernCard(
                icon: Icons.description_outlined,
                title: "Description",
                child: _buildDescriptionCard(controller),
              ),
              _modernCard(
                icon: Icons.category_outlined,
                title: "Categories & Structure",
                child: _buildCategoriesCard(context, controller),
              ),
              _modernCard(
                icon: Icons.image_outlined,
                title: "Images & Media",
                child: _buildImagesCard(context, controller),
              ),
              const SizedBox(height: 30),
              FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 24),
                label: const Text(
                  "Save Product",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () => controller.saveProduct(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────── Modern Card Wrapper ─────────
  Widget _modernCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.grey.shade200,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.indigo.shade100,
                  child: Icon(icon, color: Colors.indigo.shade700, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const Divider(height: 25, thickness: 1),
            child,
          ],
        ),
      ),
    );
  }

  // ───────── Product Details ─────────
  Widget _buildProductDetailsCard(AddProductController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputField(controller.nameController, "Product Name *"),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _inputField(controller.skuController, "SKU")),
            const SizedBox(width: 16),
            Expanded(
              child: _inputField(
                controller.priceController,
                "Price *",
                prefix: '\$',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid price';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _inputField(
          controller.stockController,
          "Stock Quantity *",
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v!.isEmpty) return 'Required';
            if (int.tryParse(v) == null) return 'Invalid number';
            return null;
          },
        ),
      ],
    );
  }

  // ───────── Input Field ─────────
  Widget _inputField(
    TextEditingController controller,
    String label, {
    String? prefix,
    String? hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final bool isRequired = label.contains('*');
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: isRequired ? label.replaceAll(' *', '') : label,
        suffixIcon: isRequired
            ? const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: Icon(Icons.star, size: 16, color: Colors.red),
              )
            : null,
        prefixText: prefix,
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
      ),
      validator:
          validator ??
          (v) => (isRequired && v!.isEmpty) ? 'This field is required' : null,
    );
  }

  // ───────── Description ─────────
  Widget _buildDescriptionCard(AddProductController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter the full product description below.",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: HtmlEditor(
            controller: controller.htmlController,
            htmlEditorOptions: const HtmlEditorOptions(
              hint: "Start typing your product description...",
              autoAdjustHeight: true,
            ),
            otherOptions: const OtherOptions(height: 300),
          ),
        ),
      ],
    );
  }

  // ───────── Categories Card ─────────
  Widget _buildCategoriesCard(
    BuildContext context,
    AddProductController controller,
  ) {
    final bool canEdit = controller.model.selectedCategoryIds.length == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Action Buttons ──
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Parent'),
              onPressed: () =>
                  controller.openAddCategoryDialog(context, parentId: 0),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.call_split),
              label: const Text('Add Sub'),
              onPressed: controller.model.selectedCategoryIds.isEmpty
                  ? null
                  : () => controller.openAddCategoryDialog(
                      context,
                      parentId: controller.model.selectedCategoryIds.first,
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade50,
                foregroundColor: Colors.indigo.shade700,
                elevation: 0,
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
              onPressed: canEdit
                  ? () {
                      final sel = controller.model.checkedList.first;
                      controller.openEditCategoryDialog(
                        context,
                        id: sel['id'] as int,
                        currentName: sel['value'] as String,
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canEdit ? Colors.orange.shade50 : null,
                foregroundColor: canEdit ? Colors.orange.shade700 : null,
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "Choose categories for your product. Parent categories are displayed first. Click the expand icon (>) next to a category to view its subcategories.",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 8),

        // ── TREE ──
        controller.model.loadingCategories
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 50.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : Container(
                height: 400, // Fixed height for scrolling
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GenerateTree(
                    data: controller.model.treeListData,
                    onChecked: (TreeNode node, bool isChecked, int commonID) => controller.updateCheckedCategories(node, isChecked, commonID),
                    selectOneToAll: false,
                  ),
                ),
              ),
      ],
    );
  }

  // ───────── Images & Camera Support ─────────
  Widget _buildImagesCard(
    BuildContext context,
    AddProductController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Main Product Image",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),

        // ── Main Image ──
        GestureDetector(
          onTap: () async {
            final result = await showModalBottomSheet<String>(
              context: context,
              builder: (_) => _buildImageSourceSheet(context, controller),
            );
            if (result == 'camera') {
              await controller.pickMainImage(fromCamera: true);
            } else if (result == 'gallery') {
              await controller.pickMainImage(fromCamera: false);
            } else if (result == 'live_camera') {
              await _showCameraPreview(context, controller);
            }
          },
          child: Container(
            height: 150,
            width: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: controller.model.mainImageBase64 != null
                    ? Colors.blue.shade700
                    : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: controller.model.mainImageBase64 != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(controller.model.mainImageBase64!),
                      fit: BoxFit.cover,
                      height: 150,
                      width: 250,
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 40,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text("Tap to pick main image"),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Sub Images ──
        const Text(
          "Additional Gallery Images",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            InkWell(
              onTap: () async {
                final result = await showModalBottomSheet<String>(
                  context: context,
                  builder: (_) => _buildImageSourceSheet(context),
                );
                if (result == 'camera') {
                  await controller.pickSubImages(fromCamera: true);
                } else if (result == 'gallery') {
                  await controller.pickSubImages(fromCamera: false);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    size: 30,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            ...List.generate(
              controller.model.subImagesBase64.length,
              (index) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(controller.model.subImagesBase64[index]),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: GestureDetector(
                      onTap: () => controller.removeSubImage(index),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ───────── Bottom Sheet: Camera or Gallery ─────────
  Widget _buildImageSourceSheet(BuildContext context, [AddProductController? controller]) {
    final bool showLiveCamera = controller != null && controller.isCameraInitialized;
    return SafeArea(
      child: Wrap(
        children: [
          if (showLiveCamera)
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Live Camera Preview'),
              onTap: () async {
                await controller.initializeCamera();
                Navigator.pop(context, 'live_camera');
              },
            ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take Photo'),
            onTap: () async {
              final status = await Permission.camera.request();
              if (status.isGranted) {
                Navigator.pop(context, 'camera');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera permission denied')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showCameraPreview(BuildContext context, AddProductController controller) async {
    if (!controller.isCameraInitialized || controller.cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not available')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 300,
              height: 400,
              child: CameraPreview(controller.cameraController!),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await controller.pickMainImage(fromCamera: true);
                  },
                  child: const Text('Capture'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
