import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'views/edit_product_page.dart';
import 'controllers/auth_controller.dart';
import 'models/pub_var.dart' as pub_var;
import 'constants/theme_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authController = AuthController();
  final session = await authController.loadSession();
  final initialRoute = session != null ? AppRoutes.dashboard : AppRoutes.login;

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin',
      theme: ThemeConstants.getLightTheme(),
      initialRoute: initialRoute,
      routes: AppRoutes.getRoutes(),
      onGenerateRoute: (settings) {
        // Route guard: Check access before allowing navigation
        if (settings.name != AppRoutes.login &&
            !AppRoutes.hasAccess(settings.name!, pub_var.userRole)) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: Text('Access Denied: Insufficient Permissions'),
              ),
            ),
          );
        }

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
