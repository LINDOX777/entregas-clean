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
  // _allItems guarda a lista completa vinda da API
  List<DeliveryItem> _allItems = [];
  String? _selectedCompanyFilter;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    // Adicionei um listener para garantir que a tela atualize ao trocar de aba
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) setState(() {});
    });
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
      // CARREGA TUDO: Removemos o filtro de company aqui para carregar todas
      // as entregas e permitir a filtragem rápida localmente (client-side).
      final list = await api.listDeliveries(courierId: widget.courierId);
      if (!mounted) return;
      setState(() {
        _allItems = list;
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

  // Gera a lista de empresas baseada no que veio da API
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

  // LÓGICA PRINCIPAL DE FILTRAGEM
  List<DeliveryItem> _filteredByTab(int index) {
    // 1. Começa com a lista completa
    List<DeliveryItem> filtered = List.from(_allItems);

    // 2. Aplica o filtro de Empresa (se houver alguma selecionada)
    if (_selectedCompanyFilter != null) {
      filtered = filtered
          .where((e) => e.company == _selectedCompanyFilter)
          .toList();
    }

    // 3. Aplica o filtro de Status (baseado na aba)
    switch (index) {
      case 0: // Pendentes
        filtered = filtered.where((e) => e.status == "pending").toList();
        break;
      case 1: // Aprovadas
        filtered = filtered.where((e) => e.status == "approved").toList();
        break;
      case 2: // Reprovadas
        filtered = filtered.where((e) => e.status == "rejected").toList();
        break;
      // case 3 é "Todas", então não filtramos status
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

    // Calculamos a lista a ser exibida com base na aba atual
    final currentList = _loading
        ? <DeliveryItem>[]
        : _filteredByTab(_tabs.index);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courierName),
        bottom: TabBar(
          controller: _tabs,
          // onTap força o setState para atualizar a lista ao clicar na aba
          onTap: (v) => setState(() {}),
          tabs: const [
            Tab(text: "Pendentes"),
            Tab(text: "Aprovadas"),
            Tab(text: "Reprovadas"),
            Tab(text: "Todas"),
          ],
        ),
      ),
      // Botões de filtro no rodapé
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
                        // Não chamamos _load() aqui, pois a filtragem é local
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
                              _selectedCompanyFilter = selected
                                  ? company
                                  : null;
                            });
                            // Não chamamos _load() aqui, pois a filtragem é local
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
          : RefreshIndicator(
              onRefresh: _load,
              child: currentList.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Text(
                            "Nenhuma entrega encontrada com estes filtros.",
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: currentList.length,
                      itemBuilder: (_, i) {
                        final d = currentList[i];
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
                                      borderRadius: BorderRadius.circular(999),
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
                                  if (d.notes != null && d.notes!.isNotEmpty)
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
                                      onPressed: () => Navigator.pop(context),
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
            ),
    );
  }
}
