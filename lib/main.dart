import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();
  runApp(MyApp(storage: storage));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.storage});

  final StorageService storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Ventas E-commerce',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: storage.isLoggedIn ? '/' : '/login',
      routes: {
        '/login': (context) => LoginScreen(
              authService: AuthService(),
              storage: storage,
            ),
        '/': (context) => MainScreen(storage: storage),
      },
    );
  }
}
