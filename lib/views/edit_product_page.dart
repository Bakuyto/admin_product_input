// ─────────────────────────────────────────────────────────────────────────────
//  edit_product_page.dart (Modern UI – Update / Delete Product)
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
  final int productId;
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
//  MODERN VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _EditProductView extends StatefulWidget {
  const _EditProductView();

  @override
  State<_EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends State<_EditProductView>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<EditProductController>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // -------------------------------------------------
    //  Loading / Error handling
    // -------------------------------------------------
    if (ctrl.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (ctrl.errorMessage != null) {
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
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(ctrl.errorMessage!, textAlign: TextAlign.center),
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

    // -------------------------------------------------
    //  Main UI
    // -------------------------------------------------
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Edit Product',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, primary.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            tooltip: 'Delete product',
            onPressed: () => _confirmDelete(context, ctrl),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: ctrl.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildModernCard(
                  icon: Icons.inventory_2_rounded,
                  title: "Product Details",
                  accent: Colors.blue.shade600,
                  child: _buildProductDetails(ctrl),
                ),
                _buildModernCard(
                  icon: Icons.description_rounded,
                  title: "Description",
                  accent: Colors.green.shade600,
                  child: _buildDescription(ctrl),
                ),
                _buildModernCard(
                  icon: Icons.category_rounded,
                  title: "Categories & Structure",
                  accent: Colors.purple.shade600,
                  child: _buildCategories(context, ctrl),
                ),
                _buildModernCard(
                  icon: Icons.collections_rounded,
                  title: "Images & Media",
                  accent: Colors.orange.shade600,
                  child: _buildImages(context, ctrl),
                ),
                const SizedBox(height: 32),
                _buildActionButtons(primary, ctrl, context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────
  //  Modern Card Wrapper
  // ──────────────────────────────────────
  Widget _buildModernCard({
    required IconData icon,
    required String title,
    required Color accent,
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
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, accent.withOpacity(0.7)],
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

  // ──────────────────────────────────────
  //  Product Details
  // ──────────────────────────────────────
  Widget _buildProductDetails(EditProductController c) {
    return Column(
      children: [
        _modernInput(c.nameController, "Product Name *", Icons.title),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _modernInput(c.skuController, "SKU", Icons.qr_code),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _modernInput(
                c.priceController,
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
        _modernInput(
          c.stockController,
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

  Widget _modernInput(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final required = label.contains('*');
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? label.replaceAll(' *', '') : label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
        suffixIcon: required
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
          (v) => (required && (v == null || v.isEmpty)) ? 'Required' : null,
    );
  }

  // ──────────────────────────────────────
  //  Description
  // ──────────────────────────────────────
  Widget _buildDescription(EditProductController c) {
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
              controller: c.htmlController,
              htmlEditorOptions: HtmlEditorOptions(
                initialText: c.model.description,
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
              callbacks: Callbacks(
                onChangeContent: (content) {
                  c.model.description = content ?? '';
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────
  //  Categories
  // ──────────────────────────────────────
  Widget _buildCategories(BuildContext ctx, EditProductController c) {
    final canEdit = c.model.selectedCategoryIds.length == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _actionChip(
              label: 'Add Parent',
              icon: Icons.add_circle_outline,
              onTap: () => c.openAddCategoryDialog(ctx, parentId: 0),
            ),
            _actionChip(
              label: 'Add Sub',
              icon: Icons.call_split,
              onTap: c.model.selectedCategoryIds.isEmpty
                  ? null
                  : () => c.openAddCategoryDialog(
                      ctx,
                      parentId: c.model.selectedCategoryIds.first,
                    ),
              enabled: c.model.selectedCategoryIds.isNotEmpty,
            ),
            _actionChip(
              label: 'Edit',
              icon: Icons.edit_outlined,
              onTap: canEdit
                  ? () {
                      final sel = c.model.checkedList.first;
                      c.openEditCategoryDialog(
                        ctx,
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
          child: c.model.loadingCategories
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GenerateTree(
                    data: c.model.treeListData,
                    onChecked: (node, isChecked, commonID) =>
                        c.updateCheckedCategories(node, isChecked, commonID),
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

  // ──────────────────────────────────────
  //  Images & Media
  // ──────────────────────────────────────
  Widget _buildImages(BuildContext ctx, EditProductController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Main Product Image"),
        const SizedBox(height: 12),
        Center(
          child: _imagePickerBox(
            context: ctx,
            imageBase64: c.model.mainImageBase64,
            onTap: () => _showImageSourceSheet(ctx, (src) {
              if (src == 'camera') {
                c.pickMainImage(fromCamera: true);
              } else if (src == 'gallery') {
                c.pickMainImage(fromCamera: false);
              } else if (src == 'live_camera') {
                _showLiveCamera(ctx, c);
              }
            }, showLive: c.isCameraInitialized),
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
              ctx,
              () => _showImageSourceSheet(ctx, (src) {
                if (src == 'camera') {
                  c.pickSubImages(fromCamera: true);
                } else if (src == 'gallery') {
                  c.pickSubImages(fromCamera: false);
                }
              }),
            ),
            ...c.model.subImagesBase64.asMap().entries.map((e) {
              final i = e.key;
              final base64 = e.value;
              final isFirst = i == 0;

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
                  if (!isFirst)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => c.removeSubImage(i),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (isFirst)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Main Gallery',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Text(
    t,
    style: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade800,
    ),
  );

  // ─── Image Picker Box (main) ───
  Widget _imagePickerBox({
    required BuildContext context,
    required String? imageBase64,
    required VoidCallback onTap,
    required bool isMain,
    bool showLive = false,
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
                        isMain ? "Tap to change main image" : "Add",
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

  // ─── Add button for sub-images ───
  Widget _addImageButton(BuildContext ctx, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(
          Icons.add_photo_alternate_outlined,
          size: 36,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ─── Gallery thumbnail with remove ───
  Widget _galleryThumb(String base64, VoidCallback onRemove) {
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

  // ─── Bottom sheet for source selection ───
  void _showImageSourceSheet(
    BuildContext ctx,
    Function(String) onSelected, {
    bool showLive = false,
  }) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _buildSourceSheet(ctx, onSelected, showLive: showLive),
    );
  }

  Widget _buildSourceSheet(
    BuildContext ctx,
    Function(String) onSelected, {
    bool showLive = false,
  }) {
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
          if (showLive)
            ListTile(
              leading: const Icon(Icons.camera, color: Colors.purple),
              title: const Text(
                'Live Camera Preview',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onSelected('live_camera');
              },
            ),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: Colors.blue),
            title: const Text(
              'Take Photo',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              final p = await Permission.camera.request();
              if (p.isGranted) {
                Navigator.pop(ctx);
                onSelected('camera');
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
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
              Navigator.pop(ctx);
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
            onTap: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  // ─── Live Camera Dialog ───
  Future<void> _showLiveCamera(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: SizedBox(
                width: 320,
                height: 420,
                child: CameraPreview(c.cameraController!),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera),
                    label: const Text('Capture'),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await c.pickMainImage(fromCamera: true);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────
  //  Action Buttons (Update / Cancel)
  // ──────────────────────────────────────
  Widget _buildActionButtons(
    Color primary,
    EditProductController c,
    BuildContext ctx,
  ) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 58,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save_outlined, size: 26),
              label: const Text(
                "Update Product",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              onPressed: () => c.updateProduct(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 58,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined, size: 26),
              label: const Text(
                "Cancel",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────
  //  Delete Confirmation
  // ──────────────────────────────────────
  Future<void> _confirmDelete(
    BuildContext ctx,
    EditProductController ctrl,
  ) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
}
