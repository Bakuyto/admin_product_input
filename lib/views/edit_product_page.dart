// ─────────────────────────────────────────────────────────────────────────────
//  edit_product_page.dart (Update / Delete Product)
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:generate_tree/treeNode.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:generate_tree/generate_tree.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/edit_product_controller.dart';

class EditProductPage extends StatefulWidget {
  final int productId; // <-- passed from list
  const EditProductPage({super.key, required this.productId});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late final EditProductController controller;

  @override
  void initState() {
    super.initState();
    controller = EditProductController(widget.productId)..init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: const _EditProductView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  UI
// ─────────────────────────────────────────────────────────────────────────────
class _EditProductView extends StatefulWidget {
  const _EditProductView();

  @override
  State<_EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends State<_EditProductView> {
  TreeNode _mapToTreeNode(Map<String, dynamic> map) {
    return TreeNode(
      id: map['id'] as int,
      title: map['value'] as String,
      children: (map['children'] as List<Map<String, dynamic>>).map(_mapToTreeNode).toList(),
      checked: false,
      show: true,
      pid: 0,
      commonID: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EditProductController>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // Ensure we set the HtmlEditor content once after loading completes
    // (HtmlEditor may ignore initialText when it's constructed before data arrives)
    if (!controller.isLoading && controller.errorMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          // setText is safe to call repeatedly; guard with a flag to avoid extra calls
          if (controller.model.description.isNotEmpty) {
            controller.htmlController.setText(controller.model.description);
          } else {
            controller.htmlController.setText('');
          }
        } catch (_) {
          // ignore failures - editor may not be ready yet
        }
      });
    }

    // Show loading while fetching the product
    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Description will be provided to the HtmlEditor via initialText below.

    // Show error if loading failed
    if (controller.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load product',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Edit Product'),
        centerTitle: true,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            tooltip: 'Delete product',
            onPressed: () => _confirmDelete(context, controller),
          ),
        ],
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
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save_outlined, size: 24),
                      label: const Text(
                        "Update Product",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => controller.updateProduct(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cancel_outlined, size: 24),
                      label: const Text(
                        "Cancel",
                        style: TextStyle(fontSize: 18),
                      ),
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: BorderSide(color: primary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────── Confirmation dialog for delete ──────
  Future<void> _confirmDelete(
    BuildContext ctx,
    EditProductController ctrl,
  ) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete product?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ctrl.deleteProduct(ctx);
    }
  }

  // ────── Card wrapper (same as Add page) ──────
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

  // ────── Product details ──────
  Widget _buildProductDetailsCard(EditProductController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputField(c.nameController, "Product Name *"),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _inputField(c.skuController, "SKU")),
            const SizedBox(width: 16),
            Expanded(
              child: _inputField(
                c.priceController,
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
          c.stockController,
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

  Widget _inputField(
    TextEditingController ctrl,
    String label, {
    String? prefix,
    String? hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final required = label.contains('*');
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? label.replaceAll(' *', '') : label,
        suffixIcon: required
            ? const Padding(
                padding: EdgeInsets.only(right: 12),
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
          validator ?? (v) => (required && v!.isEmpty) ? 'Required' : null,
    );
  }

  // ────── Description ──────
  Widget _buildDescriptionCard(EditProductController c) {
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
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: HtmlEditor(
            controller: c.htmlController,
            htmlEditorOptions: HtmlEditorOptions(
              initialText: c.model.description,
              hint: "Product description...",
              autoAdjustHeight: true,
            ),
            otherOptions: const OtherOptions(height: 300),
            callbacks: Callbacks(
              onChangeContent: (String? content) {
                c.model.description = content ?? '';
              },
            ),
          ),
        ),
      ],
    );
  }

  // ────── Categories ──────
  Widget _buildCategoriesCard(BuildContext ctx, EditProductController c) {
    final canEdit = c.model.selectedCategoryIds.length == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Parent'),
              onPressed: () => c.openAddCategoryDialog(ctx, parentId: 0),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.call_split),
              label: const Text('Add Sub'),
              onPressed: c.model.selectedCategoryIds.isEmpty
                  ? null
                  : () => c.openAddCategoryDialog(
                      ctx,
                      parentId: c.model.selectedCategoryIds.first,
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
                      final sel = c.model.checkedList.first;
                      c.openEditCategoryDialog(
                        ctx,
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
        c.model.loadingCategories
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: CircularProgressIndicator(),
                ),
              )
            : Container(
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GenerateTree(
                    data: c.model.treeListData,
                    onChecked: (TreeNode node, bool isChecked, int commonID) => c.updateCheckedCategories(node, isChecked, commonID),
                    selectOneToAll: false,
                  ),
                ),
              ),
      ],
    );
  }

  // ────── Images ──────
  Widget _buildImagesCard(BuildContext ctx, EditProductController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Main Product Image",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final src = await showModalBottomSheet<String>(
              context: ctx,
              builder: (_) => _imageSourceSheet(ctx, c),
            );
            if (src == 'camera') {
              await c.pickMainImage(fromCamera: true);
            } else if (src == 'gallery') {
              await c.pickMainImage(fromCamera: false);
            } else if (src == 'live_camera') {
              await _showCameraPreview(ctx, c);
            }
          },
          child: Container(
            height: 150,
            width: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: c.model.mainImageBase64 != null
                    ? Colors.blue.shade700
                    : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: c.model.mainImageBase64 != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(c.model.mainImageBase64!),
                      fit: BoxFit.cover,
                      width: 250,
                      height: 150,
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
                        Text("Tap to change main image"),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
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
                final src = await showModalBottomSheet<String>(
                  context: ctx,
                  builder: (_) => _imageSourceSheet(ctx),
                );
                if (src == 'camera') {
                  await c.pickSubImages(fromCamera: true);
                } else if (src == 'gallery') {
                  await c.pickSubImages(fromCamera: false);
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
              c.model.subImagesBase64.length,
              (i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(c.model.subImagesBase64[i]),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: GestureDetector(
                      onTap: () => c.removeSubImage(i),
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

  Widget _imageSourceSheet(BuildContext ctx, [EditProductController? c]) {
    final live = c != null && c.isCameraInitialized;
    return SafeArea(
      child: Wrap(
        children: [
          if (live)
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Live Camera Preview'),
              onTap: () => Navigator.pop(ctx, 'live_camera'),
            ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take Photo'),
            onTap: () async {
              final p = await Permission.camera.request();
              if (p.isGranted) Navigator.pop(ctx, 'camera');
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Future<void> _showCameraPreview(
    BuildContext ctx,
    EditProductController c,
  ) async {
    if (!c.isCameraInitialized || c.cameraController == null) {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(const SnackBar(content: Text('Camera not available')));
      return;
    }
    await showDialog(
      context: ctx,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 300,
              height: 400,
              child: CameraPreview(c.cameraController!),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await c.pickMainImage(fromCamera: true);
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
