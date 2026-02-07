import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../api/auth_api.dart';
import '../storage/token_storage.dart';
import 'admin_home_screen.dart';
import 'courier_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  Future<void> _doLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = await AuthApi.build();
      final res = await api.login(_username.text.trim(), _password.text);

      final token = res["access_token"] as String;
      final role = res["role"] as String;
      final name = res["name"] as String;

      await TokenStorage.saveSession(token: token, role: role, name: name);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => role == "admin"
              ? const AdminHomeScreen()
              : const CourierHomeScreen(),
        ),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      setState(() {
        if (status == 401) {
          _error = "Usuário ou senha inválidos.";
        } else {
          _error = "Erro ao conectar no servidor: ${e.message}";
        }
      });
    } catch (e) {
      setState(() => _error = "Erro inesperado: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (_, c) {
            final wide = c.maxWidth > 700;

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  "Entregas",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: cs.onBackground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Entre para registrar e aprovar entregas.",
                  style: TextStyle(
                    fontSize: 16,
                    color: cs.onBackground.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 26),
                TextField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: "Usuário",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: "Senha",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.withOpacity(0.35)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _doLogin,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            "ENTRAR",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                //Text(
                //"Dica: admin/admin123 — entregador/123456",
                //style: TextStyle(color: cs.onBackground.withOpacity(0.6)),
                //),
              ],
            );

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: wide
                      ? Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cs.primary.withOpacity(0.22),
                                      cs.secondary.withOpacity(0.14),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.local_shipping_outlined,
                                      size: 42,
                                      color: cs.primary,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Controle de entregas\nsimples e rápido.",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: cs.onBackground,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "• Entregador envia foto\n• Admin aprova/reprova\n• Totais por quinzena",
                                      style: TextStyle(
                                        color: cs.onBackground.withOpacity(
                                          0.75,
                                        ),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: content,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: content,
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
