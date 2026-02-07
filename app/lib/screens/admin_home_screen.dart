import 'package:dio/dio.dart'; // <--- Necessário para tratar o erro 401
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/deliveries_api.dart';
import '../storage/token_storage.dart';
import 'admin_couriers_screen.dart';
import 'login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _loading = true;

  // Estatísticas Reais
  int _totalCouriers = 0;
  int _deliveriesToday = 0;
  int _pendingApprovals = 0;

  // Dados do gráfico
  List<Map<String, dynamic>> _weeklyStats = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);
    try {
      final delivApi = await DeliveriesApi.build();

      // ✅ CHAMA A NOVA ROTA DO BACKEND
      final stats = await delivApi.getAdminStats();

      // Processa o gráfico vindo do backend
      final chartData = List<Map<String, dynamic>>.from(stats['weekly_chart']);

      // Formata os dados para o Widget
      final formattedChart = chartData.map((d) {
        final date = DateTime.parse(d['date']);
        final isToday = DateTime.now().day == date.day;
        return {
          "label": DateFormat(
            'E',
            'pt_BR',
          ).format(date)[0].toUpperCase(), // S, T, Q...
          "value": d['count'],
          "isToday": isToday,
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _totalCouriers = stats['total_couriers'];
        _pendingApprovals = stats['total_pending'];
        _deliveriesToday = stats['total_today'];
        _weeklyStats = formattedChart;
      });
    } on DioException catch (e) {
      // --- TRATAMENTO DE SESSÃO EXPIRADA (401) ---
      if (e.response?.statusCode == 401) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sessão expirada. Faça login novamente."),
              backgroundColor: Colors.orange,
            ),
          );
          _logout(); // Força a saída para limpar o token antigo
        }
        return;
      }

      // Outros erros de conexão
      debugPrint("Erro Dio: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro de conexão ao carregar dados."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro genérico: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro inesperado: $e")));
      }
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Painel de Controle",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              "Visão geral do sistema",
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh),
            tooltip: "Atualizar dados",
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: "Sair",
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SEÇÃO 1: CARDS DE DESTAQUE ---
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: "Entregadores",
                            value: "$_totalCouriers",
                            icon: Icons.people_alt,
                            color: Colors.blue,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminCouriersScreen(),
                                ),
                              ).then((_) => _loadDashboardData());
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: "Pendentes",
                            value: "$_pendingApprovals",
                            icon: Icons.pending_actions,
                            color: _pendingApprovals > 0
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Card extra para "Entregas Hoje"
                    _StatCard(
                      title: "Entregas Hoje",
                      value: "$_deliveriesToday",
                      icon: Icons.today,
                      color: Colors.purple,
                    ),

                    const SizedBox(height: 24),

                    // --- SEÇÃO 2: GRÁFICO ---
                    Text(
                      "Movimento da Semana",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 180,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.outlineVariant.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: _weeklyStats.map((stat) {
                          final heightFactor = (stat['value'] as int) / 20.0;
                          final isToday = stat['isToday'] as bool;

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isToday)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "Hoje",
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              TweenAnimationBuilder<double>(
                                duration: const Duration(seconds: 1),
                                tween: Tween(begin: 0, end: heightFactor),
                                builder: (ctx, val, _) {
                                  return Container(
                                    width: 16,
                                    // Limita altura máxima visualmente para não estourar
                                    height: (100 * val).clamp(0, 100),
                                    decoration: BoxDecoration(
                                      color: isToday
                                          ? cs.primary
                                          : cs.primary.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                stat['label'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- SEÇÃO 3: MENU ---
                    Text(
                      "Gerenciamento",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _ActionTile(
                      title: "Gerenciar Entregadores",
                      subtitle: "Cadastrar, editar ou visualizar rotas",
                      icon: Icons.motorcycle,
                      color: cs.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminCouriersScreen(),
                          ),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                    const SizedBox(height: 12),
                    _ActionTile(
                      title: "Relatórios Financeiros",
                      subtitle: "Exportar dados para Excel (Em breve)",
                      icon: Icons.table_chart,
                      color: Colors.green,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Funcionalidade em breve!"),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// --- WIDGETS AUXILIARES ---

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
