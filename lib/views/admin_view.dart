import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class AdminView extends StatelessWidget {
  const AdminView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Modern Color Palette
    const Color primaryColor = Color(0xFF42A5F5); // Light Blue
    const Color secondaryColor = Color(0xFF1E88E5);
    const Color scaffoldBackgroundColor = Color(0xFFF5F7FA);
    const double desktopBreakpoint = 1000;

    return WillPopScope(
      onWillPop: () async {
        // Go to Login when back is pressed
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        return false; // Prevent default pop
      },
      child: Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        appBar: AppBar(
          // Disable automatic back arrow
          automaticallyImplyLeading: false,

          title: const Text(
            'Admin Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: primaryColor,
          elevation: 4,
          shadowColor: Colors.black12,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final bool isLargeScreen =
                constraints.maxWidth >= desktopBreakpoint;

            if (isLargeScreen) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sidebar
                  Container(
                    width: constraints.maxWidth * 0.28,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: _buildLargeScreenSidebar(context, secondaryColor),
                  ),
                  // Main Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLargeScreenHeader(context),
                          const SizedBox(height: 32),
                          _buildCardGrid(context, constraints.maxWidth * 0.72),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSmallScreenHeader(context),
                    const SizedBox(height: 24),
                    _buildCardGrid(context, constraints.maxWidth),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
  // -----------------------------------------------------------------------
  // ⭐ MODERN DESKTOP UI COMPONENTS
  // -----------------------------------------------------------------------

  /// Builds the large, clear header for the main content area (Desktop)
  Widget _buildLargeScreenHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tool Access & Management',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select an action to begin managing the application and inventory.',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  /// Builds the Summary Sidebar (Desktop) - IMPROVED
  Widget _buildLargeScreenSidebar(BuildContext context, Color activeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting Card
        Card(
          elevation: 4, // Subtle elevation for the greeting card
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: const Color(0xFFE3F2FD), // Very light blue for background
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Overview of key metrics:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey[600]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Quick Stats Section
        Text(
          'Quick Stats',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const Divider(height: 20, thickness: 1),
        // Modern Info Tiles
        const InfoTile(
          icon: Icons.inventory_2_outlined, // Changed icon for product count
          title: 'Total Products',
          value: '452',
          color: Color(0xFF42A5F5),
        ),
        const SizedBox(height: 15),
        const InfoTile(
          icon: Icons.person_add_alt,
          title: 'New Customers (30d)',
          value: '12',
          color: Color(0xFFFF9800),
        ),
        const SizedBox(height: 15),
        const InfoTile(
          icon: Icons
              .warning_amber_outlined, // Changed icon to be more ticket-like
          title: 'Unresolved Tickets',
          value: '5',
          color: Color(0xFFE91E63),
        ),

        const SizedBox(height: 32),

        // Admin Tools Section (New Navigation)
        Text(
          'Admin Tools',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const Divider(height: 20, thickness: 1),

        // Navigation Links
        _SidebarItem(
          icon: Icons.dashboard_customize_outlined,
          title: 'Dashboard',
          route: '/',
          isActive: true, // Set the current view as active
          activeColor: activeColor,
        ),
        _SidebarItem(
          icon: Icons.group_outlined,
          title: 'User Management',
          route: '/manage_users',
          activeColor: activeColor,
        ),
        _SidebarItem(
          icon: Icons.settings_outlined,
          title: 'Settings & Config',
          route: '/settings',
          activeColor: activeColor,
        ),
      ],
    );
  }

  // -----------------------------------------------------------------------
  // ⭐ MOBILE/TABLET UI COMPONENTS
  // -----------------------------------------------------------------------

  /// Builds a simple header/greeting for mobile/tablet view - IMPROVED
  Widget _buildSmallScreenHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Management Tools',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Quick access to all management tools and metrics.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------------
  // ⭐ SHARED COMPONENTS
  // -----------------------------------------------------------------------

  /// Builds the GridView of cards, adapting to the available width (FIXED OVERFLOW)
  Widget _buildCardGrid(BuildContext context, double availableWidth) {
    int crossAxisCount;
    double childAspectRatio;

    if (availableWidth <= 500) {
      // Mobile: 2 columns, taller aspect ratio (0.9 makes it taller than wide)
      crossAxisCount = 2;
      childAspectRatio = 0.9;
    } else if (availableWidth <= 800) {
      // Tablet: 2 columns, slightly taller than square
      crossAxisCount = 2;
      childAspectRatio = 1.1;
    } else {
      // Desktop: 3 columns, wider aspect ratio
      crossAxisCount = 3;
      childAspectRatio = 1.4;
    }

    // Determine the number of cards to display, including the new 'User Management'
    final List<Widget> cards = [
      // 1. INPUT PRODUCTS
      _buildDashboardCard(
        context,
        icon: Icons
            .add_business_outlined, // Changed icon to be more 'add' focused
        title: 'Input New Products',
        route: '/input_products',
        color: const Color(0xFF4CAF50),
        secondaryColor: const Color(0xFFE8F5E9),
        subtitle: 'Add new items to the inventory.',
      ),
      // 2. PRODUCT MANAGEMENT
      _buildDashboardCard(
        context,
        icon: Icons.inventory_2_outlined, // Use a more general inventory icon
        title: 'Manage Products',
        route: '/list_products',
        color: const Color(0xFF03A9F4),
        secondaryColor: const Color(0xFFE1F5FE),
        subtitle: 'View, Update, and Delete inventory items.',
      ),
      // 3. VIDEO MANAGEMENT
      _buildDashboardCard(
        context,
        icon: Icons.video_collection_outlined,
        title: 'Manage Videos',
        route: '/manage_videos',
        color: const Color(0xFFF44336),
        secondaryColor: const Color(0xFFFFEBEE),
        subtitle: 'Upload, edit, and link product videos.',
      ),
      // 4. CUSTOMER CONTACTS
      _buildDashboardCard(
        context,
        icon: Icons
            .support_agent_outlined, // Changed icon to be more 'contact' focused
        title: 'Customer Contacts',
        route: '/check_customers',
        color: const Color(0xFFFF9800),
        secondaryColor: const Color(0xFFFFF3E0),
        subtitle: 'Check and update customer information.',
      ),
      // 5. USER MANAGEMENT (NEW)
      _buildDashboardCard(
        context,
        icon: Icons.group_outlined,
        title: 'User Management',
        route: '/manage_users',
        color: const Color(0xFF673AB7),
        secondaryColor: const Color(0xFFEDE7F6),
        subtitle: 'Manage user accounts, roles, and permissions.',
      ),
      // 6. SALES ANALYTICS
      _buildDashboardCard(
        context,
        icon: Icons.insights_outlined,
        title: 'Sales Analytics',
        route: '/analytics',
        color: const Color(0xFF9C27B0),
        secondaryColor: const Color(0xFFF3E5F5),
        subtitle: 'Review sales reports and trends.',
      ),
      // 7. APP SETTINGS (Removed old settings card, using one from sidebar,
      // but kept space for future expansion if needed)
      _buildDashboardCard(
        context,
        icon: Icons.settings_outlined,
        title: 'App Settings',
        route: '/settings',
        color: const Color(0xFF795548),
        secondaryColor: const Color(0xFFEFEBE9),
        subtitle: 'Configure application preferences.',
      ),
      // 8. ADD ONE MORE CARD FOR 2x4 symmetry
      _buildDashboardCard(
        context,
        icon: Icons.attach_money,
        title: 'Price Management',
        route: '/price_management',
        color: const Color(0xFF009688),
        secondaryColor: const Color(0xFFE0F2F1),
        subtitle: 'Adjust product pricing and promotions.',
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: childAspectRatio,
      children: cards,
    );
  }

  // Helper widget for the action cards (required by _buildCardGrid)
  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required Color color,
    required Color secondaryColor,
    required String subtitle,
  }) {
    const List<BoxShadow> modernShadow = [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.05),
        offset: Offset(0, 4),
        blurRadius: 8,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: modernShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, route);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const Spacer(),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// -----------------------------------------------------------------------
// ⭐ HELPER WIDGETS
// -----------------------------------------------------------------------

/// Helper widget for the desktop summary panel
class InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const InfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// New helper widget for the sidebar navigation links
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool isActive;
  final Color activeColor;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.route,
    this.isActive = false,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.pushNamed(context, route);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? activeColor : Colors.grey[700],
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isActive ? activeColor : Colors.grey[700],
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
