// ─────────────────────────────────────────────────────────────────────────────
//  Enhanced Add Product Page (Modern UI)
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
//  MODERN UI VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _AddProductView extends StatefulWidget {
  const _AddProductView();

  @override
  State<_AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<_AddProductView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AddProductController>();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Add New Product',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview_outlined),
            onPressed: () {
              // Preview product
            },
            tooltip: 'Preview',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildModernCard(
                  icon: Icons.inventory_2_rounded,
                  title: "Product Details",
                  color: Colors.blue.shade600,
                  child: _buildProductDetailsCard(controller),
                ),
                _buildModernCard(
                  icon: Icons.description_rounded,
                  title: "Description",
                  color: Colors.green.shade600,
                  child: _buildDescriptionCard(controller),
                ),
                _buildModernCard(
                  icon: Icons.category_rounded,
                  title: "Categories & Structure",
                  color: Colors.purple.shade600,
                  child: _buildCategoriesCard(context, controller),
                ),
                _buildModernCard(
                  icon: Icons.collections_rounded,
                  title: "Images & Media",
                  color: Colors.orange.shade600,
                  child: _buildImagesCard(context, controller),
                ),
                const SizedBox(height: 32),
                _buildSaveButton(primaryColor, controller, context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────── Enhanced Modern Card ─────────
  Widget _buildModernCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 18),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────── Product Details ─────────
  Widget _buildProductDetailsCard(AddProductController controller) {
    return Column(
      children: [
        _modernInputField(
          controller.nameController,
          "Product Name *",
          Icons.title,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _modernInputField(
                controller.skuController,
                "SKU",
                Icons.qr_code,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _modernInputField(
                controller.priceController,
                "Price *",
                Icons.attach_money,
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
        const SizedBox(height: 18),
        _modernInputField(
          controller.stockController,
          "Stock Quantity *",
          Icons.inventory,
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

  // ───────── Modern Input Field ─────────
  Widget _modernInputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final bool isRequired = label.contains('*');
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: isRequired ? label.replaceAll(' *', '') : label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
        suffixIcon: isRequired
            ? const Icon(Icons.star, size: 16, color: Colors.redAccent)
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
      ),
      validator:
          validator ??
          (v) => (isRequired && (v == null || v.isEmpty)) ? 'Required' : null,
    );
  }

  // ───────── Description ─────────
  Widget _buildDescriptionCard(AddProductController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Rich product description supports bold, lists, links, and more.",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: HtmlEditor(
              controller: controller.htmlController,
              htmlEditorOptions: const HtmlEditorOptions(
                hint: "Describe your product in detail...",
                shouldEnsureVisible: true,
              ),
              htmlToolbarOptions: const HtmlToolbarOptions(
                toolbarPosition: ToolbarPosition.aboveEditor,
                defaultToolbarButtons: [
                  StyleButtons(),
                  FontButtons(clearAll: false),
                  ColorButtons(),
                  ListButtons(),
                  ParagraphButtons(),
                ],
              ),
              otherOptions: const OtherOptions(height: 320),
            ),
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
        // Action Buttons
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _actionChip(
              label: 'Add Parent',
              icon: Icons.add_circle_outline,
              onTap: () =>
                  controller.openAddCategoryDialog(context, parentId: 0),
            ),
            _actionChip(
              label: 'Add Sub',
              icon: Icons.call_split,
              onTap: controller.model.selectedCategoryIds.isEmpty
                  ? null
                  : () => controller.openAddCategoryDialog(
                      context,
                      parentId: controller.model.selectedCategoryIds.first,
                    ),
              enabled: controller.model.selectedCategoryIds.isNotEmpty,
            ),
            _actionChip(
              label: 'Edit',
              icon: Icons.edit_outlined,
              onTap: canEdit
                  ? () {
                      final sel = controller.model.checkedList.first;
                      controller.openEditCategoryDialog(
                        context,
                        id: sel['id'] as int,
                        currentName: sel['value'] as String,
                      );
                    }
                  : null,
              enabled: canEdit,
              color: Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "Select one or more categories. Use > to expand.",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5),
        ),
        const SizedBox(height: 12),
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: controller.model.loadingCategories
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GenerateTree(
                    data: controller.model.treeListData,
                    onChecked: (node, isChecked, commonID) => controller
                        .updateCheckedCategories(node, isChecked, commonID),
                    selectOneToAll: false,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _actionChip({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool enabled = true,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      avatar: Icon(icon, size: 18),
      selected: false,
      onSelected: enabled ? (_) => onTap?.call() : null,
      backgroundColor: enabled
          ? (color?.withOpacity(0.1) ?? Colors.indigo.shade50)
          : Colors.grey.shade200,
      selectedColor: color?.withOpacity(0.2),
      labelStyle: TextStyle(
        color: enabled
            ? (color ?? Colors.indigo.shade700)
            : Colors.grey.shade500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      side: BorderSide.none,
    );
  }

  // ───────── Images & Media ─────────
  Widget _buildImagesCard(
    BuildContext context,
    AddProductController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Main Product Image"),
        const SizedBox(height: 12),
        Center(
          child: _imagePickerBox(
            context: context,
            imageBase64: controller.model.mainImageBase64,
            onTap: () => _showImageSourceSheet(context, (source) {
              if (source == 'camera') {
                controller.pickMainImage(fromCamera: true);
              } else {
                controller.pickMainImage(fromCamera: false);
              }
            }),
            isMain: true,
          ),
        ),
        const SizedBox(height: 28),
        _sectionTitle("Additional Gallery Images"),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _addImageButton(
              context,
              () => _showImageSourceSheet(context, (source) {
                if (source == 'camera') {
                  controller.pickSubImages(fromCamera: true);
                } else {
                  controller.pickSubImages(fromCamera: false);
                }
              }),
            ),
            ...controller.model.subImagesBase64.asMap().entries.map((entry) {
              int index = entry.key;
              String base64 = entry.value;
              return _galleryImageThumbnail(
                base64,
                () => controller.removeSubImage(index),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _imagePickerBox({
    required BuildContext context,
    required String? imageBase64,
    required VoidCallback onTap,
    required bool isMain,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isMain ? 180 : 110,
        width: isMain ? double.infinity : 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: imageBase64 != null
                ? Colors.blue.shade600
                : Colors.grey.shade400,
            width: imageBase64 != null ? 2.5 : 2,
          ),
          boxShadow: imageBase64 != null
              ? [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: imageBase64 != null
              ? Image.memory(
                  base64Decode(imageBase64),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              : Container(
                  color: Colors.grey.shade100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        size: isMain ? 48 : 32,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isMain ? "Tap to add main image" : "Add",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _addImageButton(BuildContext context, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: const Icon(
          Icons.add_photo_alternate_outlined,
          size: 36,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _galleryImageThumbnail(String base64, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            base64Decode(base64),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceSheet(
    BuildContext context,
    Function(String) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _buildImageSourceSheet(context, onSelected),
    );
  }

  Widget _buildImageSourceSheet(
    BuildContext context,
    Function(String) onSelected,
  ) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: Colors.blue),
            title: const Text(
              'Take Photo',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              final status = await Permission.camera.request();
              if (status.isGranted) {
                Navigator.pop(context);
                onSelected('camera');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera permission denied')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.photo_library_rounded,
              color: Colors.green,
            ),
            title: const Text(
              'Choose from Gallery',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
              onSelected('gallery');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.close_rounded, color: Colors.red),
            title: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ───────── Save Button ─────────
  Widget _buildSaveButton(
    Color primaryColor,
    AddProductController controller,
    BuildContext context,
  ) {
    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.check_circle_rounded, size: 28),
        label: const Text(
          "Save Product",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        onPressed: () => controller.saveProduct(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: primaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
