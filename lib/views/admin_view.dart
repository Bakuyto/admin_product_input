import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_flutter_app/models/pub_var.dart' as pub_var;
import '../routes/app_routes.dart';
import '../controllers/auth_controller.dart';

class AdminView extends StatefulWidget {
  const AdminView({Key? key}) : super(key: key);

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _fetchDashboardData();
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final String apiUrl = "${pub_var.apiBase}/get_dashboard_data.php";

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData.containsKey('error')) {
          throw Exception(jsonData['error']);
        }
        return {
          'total_products': jsonData['total_products']?.toString() ?? '0',
          'new_customers': jsonData['new_customers']?.toString() ?? '0',
          'unresolved_tickets':
              jsonData['unresolved_tickets']?.toString() ?? '0',
        };
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _dashboardFuture = _fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Admin Dashboard',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.blue,
          elevation: 4,
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                // Show confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  // Perform logout
                  final authController = AuthController();
                  await authController.logout();
                  // Navigate to login
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                }
              },
              tooltip: 'Logout',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double horizontalPadding = _getHorizontalPadding(
                constraints.maxWidth,
              );
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickStats(context, constraints),
                    const SizedBox(height: 32),
                    _buildSectionTitle(
                      context,
                      'Tool Access & Management',
                      textTheme,
                    ),
                    const SizedBox(height: 16),
                    _buildCardGrid(context, constraints.maxWidth),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  double _getHorizontalPadding(double width) {
    if (width <= 600) return 16;
    if (width <= 900) return 24;
    if (width <= 1200) return 32;
    return 48;
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    TextTheme textTheme,
  ) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onBackground,
      ),
    );
  }

  // === RESPONSIVE QUICK STATS ===
  Widget _buildQuickStats(BuildContext context, BoxConstraints constraints) {
    final theme = Theme.of(context);
    final width = constraints.maxWidth;
    final crossAxisCount = width <= 500 ? 1 : (width <= 900 ? 2 : 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          context,
          'Key Metrics Overview',
          Theme.of(context).textTheme,
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, dynamic>>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingGrid(crossAxisCount);
            }

            if (snapshot.hasError) {
              return _buildErrorTile(
                'Failed to load data. Pull to retry.',
                _refreshData,
              );
            }

            final data =
                snapshot.data ??
                {
                  'total_products': '0',
                  'new_customers': '0',
                  'unresolved_tickets': '0',
                };

            final List<Widget> statTiles = [
              InfoTile(
                icon: Icons.inventory_2_outlined,
                title: 'Total Products',
                value: data['total_products'],
                color: const Color(0xFF42A5F5),
              ),
              InfoTile(
                icon: Icons.person_add_alt,
                title: 'New Customers (30d)',
                value: data['new_customers'],
                color: const Color(0xFFFF9800),
              ),
              InfoTile(
                icon: Icons.warning_amber_outlined,
                title: 'Unresolved Tickets',
                value: data['unresolved_tickets'],
                color: const Color(0xFFE91E63),
              ),
            ];

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: crossAxisCount == 1 ? 4.0 : 3.5,
              children: statTiles,
            );
          },
        ),
        Divider(height: 40, thickness: 1.5, color: theme.dividerColor),
      ],
    );
  }

  Widget _buildLoadingGrid(int crossAxisCount) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: crossAxisCount == 1 ? 4.0 : 3.5,
      children: List.generate(3, (_) => const _LoadingTile()),
    );
  }

  Widget _buildErrorTile(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  // === RESPONSIVE CARD GRID ===
  Widget _buildCardGrid(BuildContext context, double availableWidth) {
    int crossAxisCount;
    double childAspectRatio;

    if (availableWidth <= 600) {
      crossAxisCount = 2;
      childAspectRatio = 0.95;
    } else if (availableWidth <= 900) {
      crossAxisCount = 3;
      childAspectRatio = 1.1;
    } else if (availableWidth <= 1200) {
      crossAxisCount = 4;
      childAspectRatio = 1.25;
    } else {
      crossAxisCount = 5;
      childAspectRatio = 1.35;
    }

    // ✅ Get user role
    final role = pub_var.userRole;

    // ✅ Admin: full access
    List<Widget> cards = [
      _buildDashboardCard(
        context,
        Icons.add_business_outlined,
        'Input New Products',
        '/input_products',
        const Color(0xFF4CAF50),
        const Color(0xFFE8F5E9),
        'Add new items to the inventory.',
      ),
      _buildDashboardCard(
        context,
        Icons.inventory_2_outlined,
        'Manage Products',
        '/list_products',
        const Color(0xFF03A9F4),
        const Color(0xFFE1F5FE),
        'View, Update, and Delete inventory items.',
      ),
      _buildDashboardCard(
        context,
        Icons.video_collection_outlined,
        'Manage Videos',
        '/manage_videos',
        const Color(0xFFF44336),
        const Color(0xFFFFEBEE),
        'Upload, edit, and link product videos.',
      ),
      _buildDashboardCard(
        context,
        Icons.support_agent_outlined,
        'Customer Contacts',
        '/check_customers',
        const Color(0xFFFF9800),
        const Color(0xFFFFF3E0),
        'Check and update customer information.',
      ),
      _buildDashboardCard(
        context,
        Icons.category_outlined,
        'Manage Categories',
        '/manage_categories',
        const Color(0xFF673AB7),
        const Color(0xFFEDE7F6),
        'Add, edit, and delete product categories.',
      ),
      _buildDashboardCard(
        context,
        Icons.insights_outlined,
        'Sales Analytics',
        '/analytics',
        const Color(0xFF9C27B0),
        const Color(0xFFF3E5F5),
        'Review sales reports and trends.',
      ),
    ];

    // ✅ User Role = 0 → Show ONLY Quick Stats + Customer Contacts
    if (role == "0") {
      cards = [
        _buildDashboardCard(
          context,
          Icons.support_agent_outlined,
          'Customer Contacts',
          '/check_customers',
          const Color(0xFFFF9800),
          const Color(0xFFFFF3E0),
          'Check and update customer information.',
        ),
      ];
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: childAspectRatio,
      children: cards,
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    IconData icon,
    String title,
    String route,
    Color color,
    Color secondaryColor,
    String subtitle,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 400;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: isSmall ? 28 : 32, color: color),
              ),
              const Spacer(),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: isSmall ? 15 : 17,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: isSmall ? 11 : 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// === INFO TILE (Responsive & Accessible) ===
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
    final textTheme = Theme.of(context).textTheme;
    final isSmall = MediaQuery.of(context).size.width < 400;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: isSmall ? 22 : 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontSize: isSmall ? 12 : 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: isSmall ? 20 : 24,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === LOADING TILE ===
class _LoadingTile extends StatelessWidget {
  const _LoadingTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Row(
          children: [
            Container(
              width: isSmall ? 38 : 42,
              height: isSmall ? 38 : 42,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ShimmerLine(width: isSmall ? 80 : 100),
                  const SizedBox(height: 6),
                  _ShimmerLine(width: isSmall ? 30 : 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  final double width;
  const _ShimmerLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
