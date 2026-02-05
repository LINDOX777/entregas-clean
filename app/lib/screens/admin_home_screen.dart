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
    final selectedCompanies = <String>[];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Cadastrar entregador"),
          content: SingleChildScrollView(
            child: Column(
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
                const SizedBox(height: 16),
                const Text("Empresas:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...["jet", "jadlog", "mercado_livre"].map((company) {
                  return CheckboxListTile(
                    title: Text(_formatCompanyName(company)),
                    value: selectedCompanies.contains(company),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          selectedCompanies.add(company);
                        } else {
                          selectedCompanies.remove(company);
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: selectedCompanies.isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text("Criar"),
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
        companies: selectedCompanies,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entregador criado!")),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro: ${e.toString()}"),
        ),
      );
    }
  }

  Future<void> _editCompaniesDialog(int courierId, List<String> currentCompanies) async {
    final selectedCompanies = List<String>.from(currentCompanies);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Editar empresas"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Selecione as empresas:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...["jet", "jadlog", "mercado_livre"].map((company) {
                  return CheckboxListTile(
                    title: Text(_formatCompanyName(company)),
                    value: selectedCompanies.contains(company),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          selectedCompanies.add(company);
                        } else {
                          selectedCompanies.remove(company);
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: selectedCompanies.isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    try {
      final api = await AuthApi.build();
      await api.updateCourierCompanies(
        courierId: courierId,
        companies: selectedCompanies,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Empresas atualizadas!")),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro: ${e.toString()}"),
        ),
      );
    }
  }

  String _formatCompanyName(String code) {
    switch (code) {
      case "jet":
        return "JeT";
      case "jadlog":
        return "Jadlog";
      case "mercado_livre":
        return "Mercado Livre";
      default:
        return code;
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
                        final companies = List<String>.from(c["companies"] ?? []);

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text(_initial(name))),
                            title: Text(name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("@$username"),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  children: companies.map((c) {
                                    return Chip(
                                      label: Text(
                                        _formatCompanyName(c),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _editCompaniesDialog(id, companies),
                                  tooltip: "Editar empresas",
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
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
