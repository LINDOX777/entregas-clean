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
  List<DeliveryItem> _allItems = [];
  String? _selectedCompanyFilter;
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
      final list = await api.listDeliveries(
        courierId: widget.courierId,
        company: _selectedCompanyFilter,
      );
      if (!mounted) return;
      setState(() {
        _allItems = list;
        _items = list;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
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

  List<String> _getAvailableCompanies() {
    final companies = _allItems.map((e) => e.company).toSet().toList();
    companies.sort();
    return companies;
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
    List<DeliveryItem> filtered = _items;
    
    // Filtro por status
    switch (index) {
      case 0:
        filtered = filtered.where((e) => e.status == "pending").toList();
        break;
      case 1:
        filtered = filtered.where((e) => e.status == "approved").toList();
        break;
      case 2:
        filtered = filtered.where((e) => e.status == "rejected").toList();
        break;
      default:
        break;
    }
    
    return filtered;
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
      persistentFooterButtons: _getAvailableCompanies().isEmpty
          ? null
          : [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text("Todas"),
                      selected: _selectedCompanyFilter == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCompanyFilter = null;
                        });
                        _load();
                      },
                    ),
                    const SizedBox(width: 8),
                    ..._getAvailableCompanies().map((company) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_formatCompanyName(company)),
                          selected: _selectedCompanyFilter == company,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCompanyFilter = selected ? company : null;
                            });
                            _load();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
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
                                      Chip(
                                        label: Text(
                                          _formatCompanyName(d.company),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
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
