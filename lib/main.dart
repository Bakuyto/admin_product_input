import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'views/edit_product_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: AppRoutes.login, // Start with login page
      routes: AppRoutes.getRoutes(),
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.editProduct) {
          final productId = settings.arguments as int?;
          if (productId != null) {
            return MaterialPageRoute(
              builder: (context) => EditProductPage(productId: productId),
            );
          }
        }
        return null;
      },
    );
  }
}
