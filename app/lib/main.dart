import 'package:flutter/material.dart';
import 'storage/token_storage.dart';
import 'screens/login_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/courier_home_screen.dart';
import 'ui/app_theme.dart';

void main() {
  runApp(const EntregasApp());
}

class EntregasApp extends StatelessWidget {
  const EntregasApp({super.key});

  Future<Widget> _getStartScreen() async {
    final token = await TokenStorage.getToken();
    final role = await TokenStorage.getRole();

    if (token == null || token.isEmpty || role == null) {
      return const LoginScreen();
    }
    if (role == "admin") return const AdminHomeScreen();
    return const CourierHomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Entregas",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: FutureBuilder<Widget>(
        future: _getStartScreen(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snap.data!;
        },
      ),
    );
  }
}
