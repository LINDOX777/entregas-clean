import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../api/auth_api.dart';
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

      // ✅ FIX: login agora é named params
      final res = await api.login(
        username: _username.text.trim(),
        password: _password.text,
      );

      // ✅ Token/role já são salvos dentro do AuthApi.login (no padrão novo)
      final role = (res["role"] ?? "").toString();

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
          _error = "Credenciais incorretas. Verifique usuário e senha.";
        } else {
          _error = "Falha na conexão: ${e.message}";
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Text(
                  "Bem-vindo",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Faça login para continuar",
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: cs.onErrorContainer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: cs.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                TextField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: "Usuário",
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
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
                  obscureText: _obscure,
                  onSubmitted: (_) => _loading ? null : _doLogin(),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _doLogin,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Entrar"),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: wide
                      ? Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 520,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      cs.primary.withOpacity(0.16),
                                      cs.tertiary.withOpacity(0.12),
                                      cs.surface.withOpacity(0.0),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: cs.outlineVariant.withOpacity(0.4),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(26),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: cs.primaryContainer,
                                        ),
                                        child: Icon(
                                          Icons.local_shipping,
                                          color: cs.onPrimaryContainer,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        "Entregas Clean",
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.6,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Controle as entregas de forma rápida e fácil",
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        "",
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(22),
                                  child: content,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Card(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
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
