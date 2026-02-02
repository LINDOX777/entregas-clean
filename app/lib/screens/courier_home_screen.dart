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
  int _fortnightTotal = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final api = await DeliveriesApi.build();
      final list = await api.listDeliveries();
      final total = await _loadFortnightTotal(api);

      if (!mounted) return;
      setState(() {
        _items = list;
        _fortnightTotal = total;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<int> _loadFortnightTotal(DeliveriesApi api) async {
    final now = DateTime.now();
    final startDay = now.day >= 16 ? 16 : 1;
    final start = DateTime(now.year, now.month, startDay);
    final startStr = DateFormat("yyyy-MM-dd").format(start);

    final res = await api.statsFortnight(start: startStr);
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

  Future<void> _sendPhoto() async {
    final img = await _picker.pickImage(
      source: ImageSource
          .gallery, // para Chrome; no Android real trocamos pra camera
      imageQuality: 75,
      maxWidth: 1280,
    );
    if (img == null) return;

    setState(() => _uploading = true);

    try {
      final api = await DeliveriesApi.build();
      await api.uploadDeliveryPhoto(img);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Entrega enviada!")));

      await _load();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao enviar ($status): ${data ?? e.message}"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Entregador"),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
                children: [
                  // HERO
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
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
                        Icon(Icons.calendar_month, color: cs.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Minha quinzena",
                                style: TextStyle(
                                  color: cs.onBackground.withOpacity(0.75),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$_fortnightTotal entregas",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    "Histórico",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cs.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text("Nenhuma entrega ainda.")),
                    ),

                  ..._items.map((d) {
                    final color = _statusColor(d.status);
                    return Card(
                      child: ListTile(
                        title: Text(
                          DateFormat("dd/MM/yyyy HH:mm").format(d.createdAt),
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
                                Text(d.notes!),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.image_outlined),
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
                  }),
                ],
              ),
            ),

      // Botão fixo (Uber-like)
      bottomSheet: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withOpacity(0.6),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _uploading ? null : _sendPhoto,
              icon: _uploading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt_outlined),
              label: Text(
                _uploading ? "Enviando..." : "ENVIAR FOTO",
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
