import 'package:flutter/material.dart';

import '../api/auth_api.dart';
import '../constants/companies.dart';
import '../storage/token_storage.dart';
import 'courier_deliveries_screen.dart';
import 'login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _couriers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = await AuthApi.build();
      final list = await api.listCouriers();
      if (!mounted) return;
      setState(() => _couriers = list);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await TokenStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _createCourierDialog() async {
    final nameC = TextEditingController();
    final userC = TextEditingController();
    final passC = TextEditingController();

    // Seleção de empresas que o entregador faz
    final selected = <String>{};

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text("Novo Entregador"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(
                    labelText: "Nome completo",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: userC,
                  decoration: const InputDecoration(
                    labelText: "Nome de usuário",
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passC,
                  decoration: const InputDecoration(
                    labelText: "Senha (mín. 6)",
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Empresas que ele faz",
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kCourierCompanies.entries.map((e) {
                    final isOn = selected.contains(e.key);
                    return FilterChip(
                      selected: isOn,
                      label: Text(e.value),
                      onSelected: (v) {
                        setLocal(() {
                          if (v) {
                            selected.add(e.key);
                          } else {
                            selected.remove(e.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (selected.isEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Selecione pelo menos 1 empresa.",
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              onPressed: () {
                if (nameC.text.trim().isEmpty ||
                    userC.text.trim().isEmpty ||
                    passC.text.trim().length < 6 ||
                    selected.isEmpty) {
                  setLocal(() {});
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text("Cadastrar"),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    try {
      final api = await AuthApi.build();
      await api.createCourier(
        name: nameC.text.trim(),
        username: userC.text.trim(),
        password: passC.text.trim(),
        companies: selected.toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entregador cadastrado com sucesso!")),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Erro ao criar (usuário pode já existir)."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _initial(String name) {
    final n = name.trim();
    if (n.isEmpty) return "?";
    return n[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // HERO HEADER (Matching Courier Style)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          cs.tertiary.withOpacity(0.15),
                          cs.primary.withOpacity(0.10),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.people_alt, color: cs.primary),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Gestão de Equipe",
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "${_couriers.length} Entregadores",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Title + Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Lista de Entregadores",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _createCourierDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Novo"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_couriers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text("Nenhum entregador cadastrado."),
                      ),
                    )
                  else
                    ..._couriers.map((c) {
                      final id = c["id"] as int;
                      final name = (c["name"] ?? "") as String;
                      final username = (c["username"] ?? "") as String;

                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CourierDeliveriesScreen(
                                  courierId: id,
                                  courierName: name,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: cs.primaryContainer,
                                  foregroundColor: cs.onPrimaryContainer,
                                  child: Text(
                                    _initial(name),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        "@$username",
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: cs.outline),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
