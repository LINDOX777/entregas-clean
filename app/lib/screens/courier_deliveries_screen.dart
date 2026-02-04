import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/deliveries_api.dart';
import '../app_config.dart';
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
        return "APROVADA";
      case "rejected":
        return "REPROVADA";
      default:
        return "PENDENTE";
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
            title: const Text("Motivo da Reprovação"),
            content: TextField(
              controller: c,
              decoration: const InputDecoration(
                hintText: "Ex: Foto ilegível",
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text("Cancelar"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, c.text.trim()),
                child: const Text("Confirmar"),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Entregas de", style: TextStyle(fontSize: 14)),
            Text(
              widget.courierName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelColor: cs.onSurfaceVariant,
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
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.2,
                            ),
                            const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text("Nenhuma entrega nesta aba."),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final d = list[i];
                            final color = _statusColor(d.status);

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat(
                                            "dd/MM/yyyy • HH:mm",
                                          ).format(d.createdAt),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_horiz,
                                            color: cs.outline,
                                          ),
                                          onSelected: (v) => _setStatus(d, v),
                                          itemBuilder: (_) => [
                                            const PopupMenuItem(
                                              value: "approved",
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text("Aprovar"),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: "rejected",
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.cancel,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text("Reprovar"),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: color.withOpacity(0.5),
                                            ),
                                          ),
                                          child: Text(
                                            _statusText(d.status),
                                            style: TextStyle(
                                              color: color,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                contentPadding: EdgeInsets.zero,
                                                clipBehavior: Clip.antiAlias,
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
                                          icon: const Icon(
                                            Icons.photo,
                                            size: 16,
                                          ),
                                          label: const Text("Ver Foto"),
                                        ),
                                      ],
                                    ),
                                    if (d.notes != null &&
                                        d.notes!.isNotEmpty) ...[
                                      const Divider(height: 24),
                                      Text(
                                        d.notes!,
                                        style: TextStyle(
                                          color: cs.error,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
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
