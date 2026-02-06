import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../api/deliveries_api.dart';
import '../config.dart';
import '../models/delivery.dart';
import '../storage/token_storage.dart';
import 'login_screen.dart';

class CourierHomeScreen extends StatefulWidget {
  const CourierHomeScreen({super.key});

  @override
  State<CourierHomeScreen> createState() => _CourierHomeScreenState();
}

class _CourierHomeScreenState extends State<CourierHomeScreen> {
  final _picker = ImagePicker();

  bool _loading = true;
  bool _uploading = false;

  List<DeliveryItem> _items = [];
  List<DeliveryItem> _filteredItems = [];
  int _fortnightTotal = 0;
  List<String> _myCompanies = [];
  String? _selectedCompanyFilter; // null = todas

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final companies = await TokenStorage.getCompanies();
      final api = await DeliveriesApi.build();
      final list = await api.listDeliveries(company: _selectedCompanyFilter);
      final total = await _loadFortnightTotal(api);

      if (!mounted) return;
      setState(() {
        _myCompanies = companies;
        _items = list;
        _filteredItems = _applyFilter(list);
        _fortnightTotal = total;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DeliveryItem> _applyFilter(List<DeliveryItem> items) {
    if (_selectedCompanyFilter == null) return items;
    return items.where((d) => d.company == _selectedCompanyFilter).toList();
  }

  Future<int> _loadFortnightTotal(DeliveriesApi api) async {
    final now = DateTime.now();
    final startDay = now.day >= 16 ? 16 : 1;
    final start = DateTime(now.year, now.month, startDay);
    final startStr = DateFormat("yyyy-MM-dd").format(start);

    final res = await api.statsFortnight(start: startStr, company: _selectedCompanyFilter);
    return (res["total"] as int?) ?? 0;
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


  Future<void> _logout() async {
    await TokenStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _startUploadFlow() async {
    if (_myCompanies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro: Nenhuma empresa vinculada ao seu perfil."),
        ),
      );
      return;
    }

    String? selectedCompany;

    // Se tiver só uma empresa, seleciona automático
    if (_myCompanies.length == 1) {
      selectedCompany = _myCompanies.first;
    } else {
      // Se tiver mais de uma, pede para escolher
      selectedCompany = await _showCompanySelector();
    }

    if (selectedCompany == null) return; // Cancelou

    // Abre a câmera/galeria
    final img = await _picker.pickImage(
      source: ImageSource.gallery, // ou Camera
      imageQuality: 75,
      maxWidth: 1280,
    );

    if (img == null) return; // Cancelou a foto

    // Envia para o Backend
    await _uploadPhoto(img, selectedCompany);
  }

  Future<String?> _showCompanySelector() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Qual empresa?"),
        children: _myCompanies.map((c) {
          return SimpleDialogOption(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            onPressed: () => Navigator.pop(ctx, c),
            child: Row(
              children: [
                const Icon(Icons.business, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  _formatCompanyName(c),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
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

  Future<void> _uploadPhoto(XFile file, String company) async {
    setState(() => _uploading = true);

    try {
      final api = await DeliveriesApi.build();

      // ✅ Enviando a foto da entrega
      await api.uploadDeliveryPhoto(file: file, company: company);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Entrega enviada com sucesso!"),
        ),
      );

      await _load(); // Recarrega a lista
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      if (!mounted) return;

      String msg = "Erro ao enviar.";
      if (status == 403) msg = "Você não pode enviar para esta empresa.";
      if (data != null && data['detail'] != null) msg = data['detail'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Minhas Entregas"),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  // HERO Section (Igual ao seu anterior)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withOpacity(0.18),
                          cs.secondary.withOpacity(0.10),
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
                          child: Icon(Icons.calendar_month, color: cs.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Resumo da Quinzena",
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$_fortnightTotal Entregas",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filtros por empresa
                  if (_myCompanies.isNotEmpty) ...[
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
                                _filteredItems = _applyFilter(_items);
                              });
                              _load();
                            },
                          ),
                          const SizedBox(width: 8),
                          ..._myCompanies.map((company) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(_formatCompanyName(company)),
                                selected: _selectedCompanyFilter == company,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCompanyFilter = selected ? company : null;
                                    _filteredItems = _applyFilter(_items);
                                  });
                                  _load();
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text(
                    "Histórico Recente",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_filteredItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          "Nenhuma entrega registrada.",
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ),

                  ..._filteredItems.map((d) {
                    final color = _statusColor(d.status);
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              contentPadding: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.network(
                                    "${AppConfig.baseUrl}${d.photoUrl}",
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Icon(Icons.broken_image),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Fechar"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.local_shipping_outlined,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat(
                                            "dd/MM • HH:mm",
                                          ).format(d.createdAt),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Empresa
                                    Chip(
                                      label: Text(
                                        _formatCompanyName(d.company),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const SizedBox(height: 8),
                                    // Status Pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: color.withOpacity(0.3),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        _statusText(d.status).toUpperCase(),
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    if (d.notes != null &&
                                        d.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        "Nota: ${d.notes}",
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.visibility_outlined,
                                color: cs.outline,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              // ✅ BOTÃO AGORA CHAMA O FLUXO NOVO
              onPressed: _uploading ? null : _startUploadFlow,
              icon: _uploading
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(
                _uploading ? "ENVIANDO..." : "NOVA ENTREGA",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
