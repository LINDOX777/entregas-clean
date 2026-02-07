import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/splash_screen.dart';
import 'ui/app_theme.dart';

// 2. MUDE PARA "async"
void main() async {
  // 3. ADICIONE ESTAS DUAS LINHAS:
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  runApp(const EntregasApp());
}

class EntregasApp extends StatelessWidget {
  const EntregasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Entregas",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
