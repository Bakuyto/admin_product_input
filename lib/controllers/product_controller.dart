import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:my_flutter_app/models/product_model.dart';

class ProductController extends ChangeNotifier {
  final ProductModel _model = ProductModel();
  final TextEditingController searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  ProductModel get model => _model;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchCtrl.dispose();
    super.dispose();
  }

  void init() {
    fetchProducts();
    searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (searchCtrl.text != _model.searchQuery) {
        _model.setSearchQuery(searchCtrl.text);
        notifyListeners();
        fetchProducts();
      }
    });
  }

  Future<void> fetchProducts([int? page]) async {
    try {
      await _model.fetchProducts(page);
      notifyListeners();
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  void onSort(String columnName) {
    _model.onSort(columnName);
    notifyListeners();
    fetchProducts();
  }

  void onPerPageChanged(int? v) {
    _model.onPerPageChanged(v);
    notifyListeners();
    fetchProducts();
  }

  void clearSearch() {
    searchCtrl.clear();
    _model.setSearchQuery('');
    notifyListeners();
    fetchProducts();
  }

  // ────────────────────────────────────────────────
  // DELETE PRODUCT
  // ────────────────────────────────────────────────
  Future<void> deleteProduct(BuildContext context, int productId) async {
    try {
      final jsonResp = await _model.deleteProduct(productId);
      if (jsonResp['success'] == true) {
        _showSnack(context, 'Product deleted successfully.', error: false);
        fetchProducts(); // Refresh list
      } else {
        throw jsonResp['message'] ?? 'Unknown error';
      }
    } catch (e) {
      _showSnack(context, 'Failed to delete: $e', error: true);
    }
  }

  // ────────────────────────────────────────────────
  // UPDATE PRODUCT
  // ────────────────────────────────────────────────
  Future<void> updateProduct(
    BuildContext context,
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
    try {
      final jsonResp = await _model.updateProduct(
        id,
        name,
        sku,
        price,
        stockQuantity,
        categoryIds,
        description,
        mainImageBytes,
        subImageBytes,
      );
      if (jsonResp['success'] == true) {
        _showSnack(context, 'Product updated successfully.', error: false);
        fetchProducts(); // Refresh list
      } else {
        throw jsonResp['message'] ?? 'Unknown error';
      }
    } catch (e) {
      _showSnack(context, 'Failed to update: $e', error: true);
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
}
