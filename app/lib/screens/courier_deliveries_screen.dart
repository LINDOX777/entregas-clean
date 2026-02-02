import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/deliveries_api.dart';
import '../config.dart';
import '../models/delivery.dart';

class CourierDeliveriesScreen extends StatefulWidget {
  final int courierId;
  final String courierName;

  const CourierDeliveriesScreen({
    super.key,
    required this.courierId,
    required this.courierName,
  });

  @override
  State<CourierDeliveriesScreen> createState() =>
      _CourierDeliveriesScreenState();
}

class _CourierDeliveriesScreenState extends State<CourierDeliveriesScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  List<DeliveryItem> _items = [];
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = await DeliveriesApi.build();
      final list = await api.listDeliveries(courierId: widget.courierId);
      if (!mounted) return;
      setState(() => _items = list);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusText(String s) {
    switch (s) {
      case "approved":
        return "Aprovada";
      case "rejected":
        return "Reprovada";
      default:
        return "Pendente";
    }
  }

  List<DeliveryItem> _filteredByTab(int index) {
    switch (index) {
      case 0:
        return _items.where((e) => e.status == "pending").toList();
      case 1:
        return _items.where((e) => e.status == "approved").toList();
      case 2:
        return _items.where((e) => e.status == "rejected").toList();
      default:
        return _items;
    }
  }

  Future<void> _setStatus(DeliveryItem item, String status) async {
    final api = await DeliveriesApi.build();

    String? notes;
    if (status == "rejected") {
      notes = await showDialog<String>(
        context: context,
        builder: (_) {
          final c = TextEditingController();
          return AlertDialog(
            title: const Text("Motivo da reprovação"),
            content: TextField(
              controller: c,
              decoration: const InputDecoration(hintText: "Ex: foto errada"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, c.text.trim()),
                child: const Text("Salvar"),
              ),
            ],
          );
        },
      );
      if (notes == null) return;
    }

    await api.setStatus(deliveryId: item.id, status: status, notes: notes);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courierName),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: "Pendentes"),
            Tab(text: "Aprovadas"),
            Tab(text: "Reprovadas"),
            Tab(text: "Todas"),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: List.generate(4, (tabIndex) {
                final list = _filteredByTab(tabIndex);

                return RefreshIndicator(
                  onRefresh: _load,
                  child: list.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text("Nada por aqui.")),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final d = list[i];
                            final color = _statusColor(d.status);

                            return Card(
                              child: ListTile(
                                title: Text(
                                  DateFormat(
                                    "dd/MM/yyyy HH:mm",
                                  ).format(d.createdAt),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: color.withOpacity(0.5),
                                          ),
                                        ),
                                        child: Text(
                                          _statusText(d.status),
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (d.notes != null &&
                                          d.notes!.isNotEmpty)
                                        Text(
                                          d.notes!,
                                          style: TextStyle(
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) => _setStatus(d, v),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: "approved",
                                      child: Text("Aprovar"),
                                    ),
                                    PopupMenuItem(
                                      value: "rejected",
                                      child: Text("Reprovar"),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Foto da entrega"),
                                      content: Image.network(
                                        "${AppConfig.baseUrl}${d.photoUrl}",
                                        fit: BoxFit.contain,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Fechar"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                );
              }),
            ),
    );
  }
}
