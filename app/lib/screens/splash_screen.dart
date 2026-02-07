import 'package:flutter/material.dart';
import '../storage/token_storage.dart';
import 'admin_couriers_screen.dart';
import 'courier_home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Configura a animação de Fade-In (aparecer suavemente)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Tempo da animação
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward(); // Inicia a animação

    // Inicia a verificação de login
    _checkAuth();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    // Espera pelo menos 2.5 segundos para o usuário ver a logo
    // (Mesmo que o celular seja rápido, a splash precisa aparecer um pouco)
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    try {
      final token = await TokenStorage.getToken();
      final role = await TokenStorage.getRole();

      // Navegação
      if (token != null && role != null) {
        // Usuário já logado, redireciona conforme o cargo
        if (role == 'admin') {
          _navigateTo(const AdminCouriersScreen());
        } else {
          _navigateTo(const CourierHomeScreen());
        }
      } else {
        // Não logado, vai para o Login
        _navigateTo(const LoginScreen());
      }
    } catch (e) {
      // Se der erro na leitura, vai para o login por segurança
      _navigateTo(const LoginScreen());
    }
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) {
          // Transição suave de Fade entre telas
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo escuro/gradiente estilo "Cinema/Netflix"
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027), // Preto azulado
              Color(0xFF203A43), // Cinza azulado escuro
              Color(0xFF2C5364), // Azul petróleo
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // AQUI VAI SUA LOGO
                // Pode trocar Icon por Image.asset('assets/logo.png')
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded, // Ícone temporário
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "ENTREGAS",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4.0, // Espaçamento chique entre letras
                    fontFamily: 'Roboto', // Ou a fonte que você preferir
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Logística Simplificada",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 60),
                // Indicador de carregamento discreto
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.5),
                    ),
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
