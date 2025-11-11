import 'package:flutter/material.dart';
import '../controllers/category_controller.dart';
import '../models/base_model.dart'; // Ensure this path and class are correct
import '../models/add_product_model.dart';

class ManageCategoriesView extends StatefulWidget {
  const ManageCategoriesView({Key? key}) : super(key: key);

  @override
  _ManageCategoriesViewState createState() => _ManageCategoriesViewState();
}

class _ManageCategoriesViewState extends State<ManageCategoriesView> {
  final CategoryController _categoryController = CategoryController();
  final AddProductModel _addProductModel = AddProductModel();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    // Assuming getCategories returns a List<Map<String, dynamic>>
    final categories = await _categoryController.getCategories();
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  Future<void> _deleteCategory(int id) async {
    // NOTE: BaseModel is assumed to have .success and .message properties
    final result = await _categoryController.deleteCategory(id);
    if (result.success) {
      _loadCategories();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ ${result.message}')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: ${result.message}')));
    }
  }

  void _showDeleteDialog(int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Confirm Deletion'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the category "$name"? This action cannot be undone and will affect all related subcategories/products.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCategory(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openEditCategoryDialog(
    BuildContext context,
    int id,
    String currentName,
  ) {
    final ctrl = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Edit Category'),
              content: TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (_) => setState(() {}), // ✅ Rebuild when typing
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
                          await _addProductModel.editCategory(id, name);
                          _loadCategories();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Updated: $name')),
                            );
                          }
                        },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openAddCategoryDialog(BuildContext context, {int parentId = 0}) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                parentId == 0 ? 'Add Main Category' : 'Add Subcategory',
              ),
              content: TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (_) => setState(() {}), // <--- Force Dialog Rebuild
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
                          await _addProductModel.addCategory(name, parentId);
                          _loadCategories();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added: $name')),
                            );
                          }
                        },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // UX/UI Enhancement: Using ExpansionTile for cleaner hierarchy.
  // FIX: Explicitly casting sub list items to Map<String, dynamic> to resolve TypeError.
  // -------------------------------------------------------------------------
  Widget _buildCategoryItem(Map<String, dynamic> category, int level) {
    // Read subcategories as List<dynamic> to avoid type issues from JSON decoding
    final subcategories = category['subcategories'] as List<dynamic>? ?? [];
    final int categoryId = int.tryParse(category['id'].toString()) ?? 0;
    final bool hasSubcategories = subcategories.isNotEmpty;
    final Color itemColor = level == 0
        ? Colors.blue.shade600
        : Colors.green.shade600;

    return Padding(
      // Indentation for subcategories
      padding: EdgeInsets.only(left: level * 16.0),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: level == 0
            ? 3
            : 1, // Higher elevation for top-level categories
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          key: ValueKey(
            categoryId,
          ), // Important for ExpansionTile state management
          initiallyExpanded: false, // Default to collapsed
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: itemColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              level == 0 ? Icons.category_rounded : Icons.folder_open_rounded,
              color: itemColor,
              size: 20,
            ),
          ),
          title: Text(
            category['name'],
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          subtitle: level > 0
              ? Text(
                  'Subcategory',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: Colors.green.shade400,
                  size: 20,
                ),
                onPressed: () =>
                    _openAddCategoryDialog(context, parentId: categoryId),
                tooltip: 'Add Subcategory',
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: Colors.orange.shade400,
                  size: 20,
                ),
                onPressed: () => _openEditCategoryDialog(
                  context,
                  categoryId,
                  category['name'],
                ),
                tooltip: 'Edit Category',
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade400,
                  size: 20,
                ),
                onPressed: () =>
                    _showDeleteDialog(categoryId, category['name']),
                tooltip: 'Delete Category',
              ),
              // Use ExpansionTile's built-in icon if subcategories exist
              if (hasSubcategories)
                const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
            ],
          ),
          // FIX APPLIED HERE: Casting each 'sub' element explicitly.
          children: hasSubcategories
              ? subcategories.map((sub) {
                  return _buildCategoryItem(
                    sub as Map<String, dynamic>,
                    level + 1,
                  );
                }).toList()
              : const [],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        return _buildCategoryItem(_categories[index], 0);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.grey.shade100],
          ),
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade700!,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadCategories,
                color: Colors.blue.shade700,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade100.withOpacity(0.5),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.storage_rounded,
                              size: 36,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Category Hierarchy',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Edit, delete, and view your nested categories.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Categories Section
                      if (_categories.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 50.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Categories Yet',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the + button to add your first top-level category.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        _buildCategoryList(),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddCategoryDialog(context),
        child: const Icon(Icons.add_rounded),
        backgroundColor: Colors.pink.shade400,
        foregroundColor: Colors.white,
        tooltip: 'Add New Category',
      ),
    );
  }
}
