import 'package:flutter/material.dart';
import 'package:my_flutter_app/views/add_video.dart';
import 'package:my_flutter_app/views/product_list.dart';
import '../views/login_view.dart';
import '../views/admin_view.dart';
import '../views/add_product_view.dart';
import '../views/edit_product_page.dart';
import '../views/manage_categories_view.dart';

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

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // Add your routes here
      home: (context) => Container(), // Replace with actual screens
      login: (context) => const LoginView(),
      dashboard: (context) => const AdminView(),
      inputProducts: (context) => const AddProductPage(),
      listProducts: (context) => const ProductListPage(),
      editProduct: (context) => const EditProductPage(
        productId: 0,
      ), // Placeholder, will be overridden by onGenerateRoute
      checkCustomers: (context) => Container(
        child: const Center(
          child: Text('Check & Update Customer Contact Page'),
        ),
      ),
      settings: (context) =>
          Container(child: const Center(child: Text('Settings Page'))),
      manageCategories: (context) => const ManageCategoriesView(),
      manageVideos: (context) => AddNewVideo(),
    };
  }
}
