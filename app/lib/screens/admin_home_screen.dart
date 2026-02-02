import 'package:flutter/material.dart';

import '../api/auth_api.dart';
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

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cadastrar entregador"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: "Nome"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: userC,
              decoration: const InputDecoration(labelText: "Usuário"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passC,
              decoration: const InputDecoration(labelText: "Senha (mín. 6)"),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Criar"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final api = await AuthApi.build();
      await api.createCourier(
        name: nameC.text.trim(),
        username: userC.text.trim(),
        password: passC.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Entregador criado!")));
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro ao criar entregador (usuário pode já existir)."),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Entregadores"),
        actions: [
          IconButton(
            onPressed: _createCourierDialog,
            tooltip: "Cadastrar entregador",
            icon: const Icon(Icons.person_add_alt_1),
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _couriers.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text("Nenhum entregador cadastrado.")),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _couriers.length,
                      itemBuilder: (_, i) {
                        final c = _couriers[i];
                        final id = c["id"] as int;
                        final name = (c["name"] ?? "") as String;
                        final username = (c["username"] ?? "") as String;

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text(_initial(name))),
                            title: Text(name),
                            subtitle: Text("@$username"),
                            trailing: const Icon(Icons.chevron_right),
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
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
