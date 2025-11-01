import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:my_flutter_app/controllers/product_controller.dart';
import 'package:my_flutter_app/routes/app_routes.dart';
import 'package:my_flutter_app/views/edit_product_page.dart';

enum LayoutMode { mobile, tablet, desktop }

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late ProductController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProductController();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- RESPONSIVE LAYOUT LOGIC ---
  LayoutMode get _layoutMode {
    final shortest = MediaQuery.of(context).size.shortestSide;
    if (shortest < 600) return LayoutMode.mobile;
    if (shortest < 840) return LayoutMode.tablet;
    return LayoutMode.desktop;
  }

  bool get _isMobile => _layoutMode == LayoutMode.mobile;
  bool get _isTablet => _layoutMode == LayoutMode.tablet;
  bool get _isDesktop => _layoutMode == LayoutMode.desktop;

  int _gridColumnCount(BuildContext context) {
    final shortest = MediaQuery.of(context).size.shortestSide;
    if (shortest < 600) return 2; // Mobile
    if (shortest < 840) return 3; // Tablet
    return 4; // Desktop
  }

  double _calculateChildAspectRatio(
    BuildContext context,
    ProductController controller,
  ) {
    final columnCount = _gridColumnCount(context);

    if (columnCount == 2) {
      return controller.model.sortColumn == 'category_name' ? 0.65 : 0.68;
    } else if (columnCount == 3) {
      return controller.model.sortColumn == 'category_name' ? 0.70 : 0.78;
    } else {
      return controller.model.sortColumn == 'category_name' ? 0.75 : 0.85;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProductController>.value(
      value: _controller,
      child: Consumer<ProductController>(
        builder: (context, controller, child) {
          final colors = Theme.of(context).colorScheme;

          final content = _isDesktop
              ? _buildDesktopLayout(colors, controller)
              : _buildGridLayout(colors, _gridColumnCount(context), controller);

          return Scaffold(
            backgroundColor: _isDesktop
                ? colors.surfaceContainerLowest
                : colors.surface,
            appBar: AppBar(
              title: Text(
                _isDesktop
                    ? 'Product Inventory Management'
                    : 'Product Inventory',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: _isDesktop ? 24 : 20,
                ),
              ),
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              elevation: 2,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              actions: [
                // Semantics(
                //   label: 'Refresh product list',
                //   child: IconButton(
                //     icon: const Icon(Icons.refresh),
                //     onPressed: controller.model.loading
                //         ? null
                //         : () => controller.fetchProducts(
                //             controller.model.currentPage,
                //           ),
                //     tooltip: 'Refresh List',
                //   ),
                // ),
                // Only show search icon on desktop
                if (_isDesktop)
                  Semantics(
                    label: controller.searchCtrl.text.isEmpty
                        ? 'Search products'
                        : 'Clear search',
                    child: IconButton(
                      icon: Icon(
                        controller.searchCtrl.text.isEmpty
                            ? Icons.search
                            : Icons.search_off,
                      ),
                      onPressed: () {
                        if (controller.searchCtrl.text.isNotEmpty) {
                          controller.clearSearch();
                        }
                      },
                      tooltip: controller.searchCtrl.text.isEmpty
                          ? 'Search'
                          : 'Clear Search',
                    ),
                  ),
              ],
            ),
            body: content,
          );
        },
      ),
    );
  }

  // --- DESKTOP LAYOUT ---
  Widget _buildDesktopLayout(ColorScheme colors, ProductController controller) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildTopControls(colors, controller),
            if (controller.model.products.isNotEmpty &&
                !controller.model.loading)
              _buildTableHeader(colors, controller),
            Expanded(
              child: controller.model.loading
                  ? const Center(child: CircularProgressIndicator())
                  : controller.model.products.isEmpty
                  ? _buildEmptyState(context, controller)
                  : RefreshIndicator(
                      onRefresh: () => controller.fetchProducts(
                        controller.model.currentPage,
                      ),
                      child: ListView.builder(
                        key: ValueKey(controller.model.currentPage),
                        itemCount: controller.model.products.length,
                        itemBuilder: (context, index) =>
                            _buildProductRowDesktop(
                              controller.model.products[index]
                                    as Map<String, dynamic>
                                ..['index'] = index,
                              controller,
                            ),
                      ),
                    ),
            ),
            if (controller.model.products.isNotEmpty &&
                !controller.model.loading)
              _buildPaginationBar(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildGridLayout(
    ColorScheme colors,
    int crossAxisCount,
    ProductController controller,
  ) {
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final isCompact = _isMobile && isLandscape;

    return Stack(
      children: [
        // === SCROLLABLE CONTENT ===
        RefreshIndicator(
          onRefresh: () =>
              controller.fetchProducts(controller.model.currentPage),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: 80, // Space for sticky pagination
            ),
            child: Column(
              children: [
                _buildTopControls(colors, controller),

                // Sort button (optional in landscape)
                if (controller.model.products.isNotEmpty &&
                    !controller.model.loading)
                  if (!isCompact) _buildSortButton(colors, controller),

                // Loading / Empty / Grid
                if (controller.model.loading)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.model.products.isEmpty)
                  _buildEmptyState(context, controller)
                else
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isMobile ? 8 : 16,
                      vertical: _isMobile ? 4 : 8,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isCompact ? 600 : double.infinity,
                      ),
                      child: Center(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: _isMobile ? 8 : 12,
                                mainAxisSpacing: _isMobile ? 8 : 12,
                                childAspectRatio: _calculateChildAspectRatio(
                                  context,
                                  controller,
                                ),
                              ),
                          itemCount: controller.model.products.length,
                          itemBuilder: (context, index) {
                            final p =
                                controller.model.products[index]
                                    as Map<String, dynamic>;
                            return _buildProductTile(
                              p,
                              controller,
                              isCompact: isCompact,
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                // Extra space at bottom
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // === STICKY PAGINATION BAR ===
        if (controller.model.products.isNotEmpty && !controller.model.loading)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: colors.surfaceContainerHighest,
              child: _buildPaginationBar(context, controller),
            ),
          ),
      ],
    );
  }

  // --- SHARED WIDGETS ---
  Widget _buildSortButton(ColorScheme colors, ProductController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => _showSortSheet(context, controller),
          icon: const Icon(Icons.sort),
          label: Text(
            'Sort by: ${controller.model.sortColumn!.toUpperCase()} (${controller.model.sortAscending ? 'ASC' : 'DESC'})',
            style: GoogleFonts.poppins(),
          ),
          style: TextButton.styleFrom(foregroundColor: colors.primary),
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context, ProductController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort Products By',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSortOption(setModalState, 'Name', 'name', controller),
                  _buildSortOption(
                    setModalState,
                    'Category',
                    'category_name',
                    controller,
                  ),
                  _buildSortOption(setModalState, 'Price', 'price', controller),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Done', style: GoogleFonts.poppins()),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => setState(() {}));
  }

  Widget _buildSortOption(
    StateSetter setModalState,
    String title,
    String columnName,
    ProductController controller,
  ) {
    return RadioListTile<String>(
      title: Text(title, style: GoogleFonts.poppins()),
      value: columnName,
      groupValue: controller.model.sortColumn,
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: (value) {
        if (value != null) {
          setModalState(() => controller.onSort(value));
        }
      },
    );
  }

  Widget _buildProductTile(
    Map<String, dynamic> p,
    ProductController controller, {
    bool isCompact = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final imageUrl = p['image_url'] ?? '';
    final priceNum = double.tryParse(p['price']?.toString() ?? '0.0') ?? 0.0;
    final price = priceNum.toStringAsFixed(2);
    final productName = p['name'] ?? 'Unnamed Product';
    final isPhone = _isMobile;

    final compactButtonStyle = TextButton.styleFrom(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 4.0 : 4.0,
        vertical: 0.0,
      ),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: isPhone ? const Size(60, 28) : null,
    );

    return Semantics(
      label: 'Product: $productName, Price: \$$price',
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.symmetric(
          horizontal: isPhone ? 0 : 12,
          vertical: isPhone ? 4 : 8,
        ),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () => print('Tapped product: $productName'),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: isPhone ? 1 : 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: colors.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: colors.surfaceVariant,
                      child: Icon(
                        Icons.broken_image,
                        size: 40,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isPhone ? 6.0 : 16.0,
                  isPhone ? 6.0 : 12.0,
                  isPhone ? 6.0 : 16.0,
                  isPhone ? 6.0 : 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      productName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: isPhone ? 14 : 18,
                        color: colors.onSurface,
                      ),
                      maxLines: isPhone ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$$price',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: isPhone ? 12 : 16,
                        color: colors.secondary,
                      ),
                    ),
                    if (controller.model.sortColumn == 'category_name') ...[
                      const SizedBox(height: 2),
                      Text(
                        p['category_name'] ?? 'Uncategorized',
                        style: GoogleFonts.poppins(
                          fontSize: isPhone ? 11 : 14,
                          color: colors.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),

                    // Action buttons (Edit / Delete)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            final id =
                                int.tryParse(p['id']?.toString() ?? '0') ?? 0;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProductPage(productId: id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                          style: compactButtonStyle,
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: () =>
                              _confirmDelete(context, controller, p),
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                          style: compactButtonStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls(ColorScheme colors, ProductController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Semantics(
          label: 'Search products',
          hint: 'Enter product name or ID',
          child: TextField(
            controller: controller.searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: GoogleFonts.poppins(
                color: colors.onSurfaceVariant.withOpacity(0.6),
              ),
              prefixIcon: Icon(Icons.search, color: colors.primary),
              suffixIcon: controller.searchCtrl.text.isNotEmpty
                  ? Semantics(
                      label: 'Clear search',
                      child: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: controller.clearSearch,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14.0,
                horizontal: 16.0,
              ),
            ),
            style: GoogleFonts.poppins(),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(ColorScheme colors, ProductController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              'Image',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          _buildSortableHeader(colors, 'Product Name', 'name', 4, controller),
          _buildSortableHeader(
            colors,
            'Category',
            'category_name',
            3,
            controller,
          ),
          _buildSortableHeader(colors, 'Price', 'price', 1, controller),
          const Expanded(flex: 1, child: SizedBox(width: 8.0)),
        ],
      ),
    );
  }

  Widget _buildSortableHeader(
    ColorScheme colors,
    String title,
    String columnName,
    double flex,
    ProductController controller,
  ) {
    final isCurrentSort = controller.model.sortColumn == columnName;
    return Expanded(
      flex: flex.toInt(),
      child: InkWell(
        onTap: () => controller.onSort(columnName),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            mainAxisAlignment: flex == 1
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCurrentSort ? colors.primary : colors.onSurface,
                ),
              ),
              if (isCurrentSort)
                AnimatedRotation(
                  turns: controller.model.sortAscending ? 0 : 0.5,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.arrow_upward,
                    size: 16,
                    color: colors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- FIXED: No overflow in action buttons ---
  Widget _buildProductRowDesktop(
    Map<String, dynamic> p,
    ProductController controller,
  ) {
    final colors = Theme.of(context).colorScheme;
    final imageUrl = p['image_url'] ?? '';
    final priceValue = p['price']?.toString();
    final priceNum = double.tryParse(priceValue ?? '0.0');
    final price = priceNum?.toStringAsFixed(2) ?? 'N/A';
    final category = p['category_name'] ?? 'Uncategorized';
    final productName = p['name'] ?? 'Unnamed Product';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => print('View details for $productName'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: p['index'] % 2 == 0
                ? colors.surfaceContainer
                : colors.surface,
            border: Border(
              bottom: BorderSide(
                color: colors.outlineVariant.withOpacity(0.3),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 48,
                      height: 48,
                      color: colors.surfaceContainer,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 48,
                      height: 48,
                      color: colors.surfaceContainer,
                      child: const Icon(Icons.inventory_2_outlined, size: 24),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  productName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '\$$price',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colors.secondary,
                  ),
                ),
              ),
              // Actions column
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Edit product',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        final id =
                            int.tryParse(p['id']?.toString() ?? '0') ?? 0;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProductPage(productId: id),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Delete product',
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _confirmDelete(context, controller, p),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext ctx,
    ProductController ctrl,
    Map<String, dynamic> p,
  ) async {
    final id = int.tryParse(p['id']?.toString() ?? '0') ?? 0;
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          'Delete "${p['name'] ?? 'this product'}"? This action cannot be undone.',
        ),
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

    if (confirmed == true) {
      await ctrl.deleteProduct(ctx, id);
    }
  }

  Widget _buildPaginationBar(
    BuildContext context,
    ProductController controller,
  ) {
    final colors = Theme.of(context).colorScheme;
    final isFirst = controller.model.currentPage <= 1;
    final isLast = controller.model.currentPage >= controller.model.totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withOpacity(0.3)),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Items per page
          Row(
            children: [
              Text(
                'Items:',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: colors.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: controller.model.perPage,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: colors.primary,
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10')),
                    DropdownMenuItem(value: 20, child: Text('20')),
                    DropdownMenuItem(value: 50, child: Text('50')),
                    DropdownMenuItem(value: 100, child: Text('100')),
                  ],
                  onChanged: controller.model.loading
                      ? null
                      : controller.onPerPageChanged,
                ),
              ),
            ],
          ),

          // Page controls
          Row(
            children: [
              SizedBox(
                width: 50,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '${controller.model.currentPage}',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(fontSize: 13),
                  onSubmitted: (value) {
                    final page = int.tryParse(value);
                    if (page != null &&
                        page >= 1 &&
                        page <= controller.model.totalPages) {
                      controller.fetchProducts(page);
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'of ${controller.model.totalPages}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  size: 18,
                  color: isFirst
                      ? colors.onSurface.withOpacity(0.3)
                      : colors.primary,
                ),
                padding: const EdgeInsets.all(4),
                onPressed: isFirst || controller.model.loading
                    ? null
                    : () => controller.fetchProducts(
                        controller.model.currentPage - 1,
                      ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: isLast
                      ? colors.onSurface.withOpacity(0.3)
                      : colors.primary,
                ),
                padding: const EdgeInsets.all(4),
                onPressed: isLast || controller.model.loading
                    ? null
                    : () => controller.fetchProducts(
                        controller.model.currentPage + 1,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ProductController controller) {
    final colors = Theme.of(context).colorScheme;
    final isSearching = controller.searchCtrl.text.isNotEmpty;
    final title = isSearching
        ? 'No results for "${controller.searchCtrl.text}"'
        : 'No products found';
    final message = isSearching
        ? 'Try a different search term or clear the search.'
        : 'Add new products or refresh to load data.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 500),
              child: Icon(
                isSearching ? Icons.search_off : Icons.inventory_2_outlined,
                size: 100,
                color: colors.onSurface.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              label: isSearching ? 'Clear search' : 'Refresh products',
              child: ElevatedButton.icon(
                icon: Icon(isSearching ? Icons.clear : Icons.refresh),
                label: Text(isSearching ? 'Clear Search' : 'Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => isSearching
                    ? controller.clearSearch()
                    : controller.fetchProducts(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
