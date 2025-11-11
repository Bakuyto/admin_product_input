import 'package:flutter/material.dart';
import '../views/login_view.dart';
import '../views/admin_view.dart';
import '../views/add_product_view.dart';
import '../views/product_list.dart';
import '../views/edit_product_page.dart';
import '../views/manage_categories_view.dart';
import '../views/customer_contact_page.dart';
import '../views/add_video.dart';
import '../models/pub_var.dart' as pub_var;

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String inputProducts = '/input_products';
  static const String listProducts = '/list_products';
  static const String editProduct = '/edit_product';
  static const String checkCustomers = '/check_customers';
  static const String settings = '/settings';
  static const String manageCategories = '/manage_categories';
  static const String manageVideos = '/manage_videos';

  static const Map<String, List<String>> roleAccess = {
    'admin': [
      dashboard,
      inputProducts,
      listProducts,
      editProduct,
      checkCustomers,
      manageCategories,
      manageVideos,
    ],
    'user': [dashboard, checkCustomers],
  };

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const SizedBox(), // placeholder
      login: (context) => const LoginView(),
      dashboard: (context) => const AdminView(),
      inputProducts: (context) => const AddProductPage(),
      listProducts: (context) => const ProductListPage(),
      editProduct: (context) =>
          const SizedBox(), // real page via onGenerateRoute
      checkCustomers: (context) => const CustomerContactPage(),
      settings: (context) =>
          Container(child: const Center(child: Text('Settings Page'))),
      manageCategories: (context) => const ManageCategoriesView(),
      manageVideos: (context) => const AddNewVideo(),
    };
  }

  static bool hasAccess(String route, String? userRole) {
    if (userRole == null) return false;
    final allowedRoutes = roleAccess[userRole == '1' ? 'admin' : 'user'] ?? [];
    return allowedRoutes.contains(route);
  }
}
