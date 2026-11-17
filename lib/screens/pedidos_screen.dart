import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/pedido_models.dart';
import '../services/pedido_service.dart';
import '../theme/app_theme.dart';

/// Pantalla de Pedidos con KPIs, gráfico de distribución y tabla paginada.
class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final PedidoService _service = PedidoService();

  // Para KPIs (muestra representativa)
  List<Pedido> _kpiPedidos = [];
  int _totalPedidos = 0;
  bool _kpiLoading = true;
  String? _kpiError;

  // Para la tabla (paginación)
  List<Pedido> _tablePedidos = [];
  int _pageOffset = 0;
  static const int _pageSize = 50;
  bool _tableLoading = true;
  String? _tableError;

  @override
  void initState() {
    super.initState();
    _loadKpis();
    _loadTable();
  }

  Future<void> _loadKpis() async {
    setState(() {
      _kpiLoading = true;
      _kpiError = null;
    });
    try {
      // Cargamos 200 pedidos para calcular KPIs representativos
      final res = await _service.getPedidos(limit: 200, offset: 0);
      if (mounted) {
        setState(() {
          _kpiPedidos = res.items;
          _totalPedidos = res.total;
          _kpiLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando KPIs de pedidos: $e');
      if (mounted) {
        setState(() {
          _kpiError = e.toString();
          _kpiLoading = false;
        });
      }
    }
  }

  Future<void> _loadTable() async {
    setState(() {
      _tableLoading = true;
      _tableError = null;
    });
    try {
      final res =
          await _service.getPedidos(limit: _pageSize, offset: _pageOffset);
      if (mounted) {
        setState(() {
          _tablePedidos = res.items;
          _tableLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando tabla de pedidos: $e');
      if (mounted) {
        setState(() {
          _tableError = e.toString();
          _tableLoading = false;
        });
      }
    }
  }

  // --- Cálculos de KPIs ---
  int get _pagados => _kpiPedidos.where((p) => p.estaPagado).length;
  int get _entregados =>
      _kpiPedidos.where((p) => p.estadoLabel == 'delivered').length;
  int get _cancelados =>
      _kpiPedidos.where((p) => p.estadoLabel == 'canceled').length;
  double get _montoTotal =>
      _kpiPedidos.fold(0, (sum, p) => sum + p.valor);
  double get _ticketPromedio =>
      _kpiPedidos.isEmpty ? 0 : _montoTotal / _kpiPedidos.length;

  Map<String, int> get _estadoCounts {
    final map = <String, int>{};
    for (final p in _kpiPedidos) {
      map[p.estadoLabel] = (map[p.estadoLabel] ?? 0) + 1;
    }
    return map;
  }

  int get _totalPages => (_totalPedidos / _pageSize).ceil();
  int get _currentPage => (_pageOffset / _pageSize).floor() + 1;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadKpis();
        await _loadTable();
      },
      color: AppColors.red,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Gestión de Pedidos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total registrado en el sistema: $_totalPedidos pedidos',
            style: const TextStyle(color: AppColors.gray, fontSize: 14),
          ),
          if (_kpiError != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(_kpiError!),
          ],
          const SizedBox(height: 24),
          _buildKpiCards(),
          const SizedBox(height: 32),
          _buildSectionTitle('Distribución por estado'),
          const SizedBox(height: 16),
          _buildEstadoChart(),
          const SizedBox(height: 32),
          _buildSectionTitle('Listado de pedidos'),
          if (_tableError != null) ...[
            const SizedBox(height: 12),
            _buildErrorBanner(_tableError!),
          ],
          const SizedBox(height: 16),
          _buildTable(),
          const SizedBox(height: 16),
          _buildPagination(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
    );
  }

  Widget _buildKpiCards() {
    if (_kpiLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWide ? 4 : 2,
          childAspectRatio: isWide ? 1.5 : 1.3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _MiniKpiCard(
              title: 'Pedidos (muestra)',
              value: '${_kpiPedidos.length}',
              icon: Icons.receipt_long,
              accent: AppColors.yellow,
            ),
            _MiniKpiCard(
              title: 'Pagados',
              value: '$_pagados',
              icon: Icons.payment,
              accent: AppColors.yellow,
            ),
            _MiniKpiCard(
              title: 'Entregados',
              value: '$_entregados',
              icon: Icons.check_circle,
              accent: AppColors.yellow,
            ),
            _MiniKpiCard(
              title: 'Cancelados',
              value: '$_cancelados',
              icon: Icons.cancel,
              accent: AppColors.red,
            ),
            _MiniKpiCard(
              title: 'Monto total',
              value: 'R\$ ${_montoTotal.toStringAsFixed(0)}',
              icon: Icons.attach_money,
              accent: AppColors.yellow,
            ),
            _MiniKpiCard(
              title: 'Ticket promedio',
              value: 'R\$ ${_ticketPromedio.toStringAsFixed(2)}',
              icon: Icons.trending_up,
              accent: AppColors.yellow,
            ),
            _MiniKpiCard(
              title: '% Pagados',
              value:
                  '${_kpiPedidos.isEmpty ? 0 : ((_pagados / _kpiPedidos.length) * 100).toStringAsFixed(0)}%',
              icon: Icons.percent,
              accent: AppColors.yellow,
            ),
            _MiniKpiCard(
              title: '% Entregados',
              value:
                  '${_kpiPedidos.isEmpty ? 0 : ((_entregados / _kpiPedidos.length) * 100).toStringAsFixed(0)}%',
              icon: Icons.local_shipping,
              accent: AppColors.yellow,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEstadoChart() {
    if (_kpiLoading || _kpiPedidos.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final counts = _estadoCounts;
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Paleta de colores para los estados (rojo, amarillo, blanco, negro)
    final palette = [
      AppColors.red,
      AppColors.yellow,
      AppColors.black,
      AppColors.redDark,
      AppColors.yellowDark,
      AppColors.blackSoft,
      AppColors.gray,
      AppColors.whiteSoft,
    ];

    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: entries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final color = palette[index % palette.length];
                  final isLargest = index == 0;
                  return PieChartSectionData(
                    value: item.value.toDouble(),
                    color: color,
                    title: '${item.value}',
                    radius: isLargest ? 70 : 60,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color == AppColors.yellow ||
                              color == AppColors.whiteSoft
                          ? AppColors.black
                          : AppColors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final item = entries[index];
                final color = palette[index % palette.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.key,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      Text(
                        '${item.value}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_tableLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_tablePedidos.isEmpty) {
      return const Center(child: Text('Sin pedidos'));
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray.withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.black),
          headingTextStyle: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          dataTextStyle: const TextStyle(fontSize: 12),
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Cliente')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Pagado')),
            DataColumn(label: Text('Monto')),
            DataColumn(label: Text('F. Estimada')),
            DataColumn(label: Text('F. Entrega')),
          ],
          rows: _tablePedidos.map((p) {
            return DataRow(cells: [
              DataCell(Text('#${p.id}')),
              DataCell(
                SizedBox(
                  width: 180,
                  child: Text(
                    p.cliente.usuario.nombreCompleto,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(_buildEstadoBadge(p.estadoLabel)),
              DataCell(
                Icon(
                  p.estaPagado ? Icons.check_circle : Icons.cancel,
                  color: p.estaPagado ? Colors.green : AppColors.red,
                  size: 18,
                ),
              ),
              DataCell(Text('R\$ ${p.valor.toStringAsFixed(2)}')),
              DataCell(Text(_formatDate(p.fechaEntregaEstimada))),
              DataCell(
                Text(
                  p.fechaEntregaReal != null
                      ? _formatDate(p.fechaEntregaReal!)
                      : '-',
                  style: TextStyle(
                    color: p.fechaEntregaReal != null
                        ? AppColors.black
                        : AppColors.gray,
                  ),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color bg;
    Color fg;
    switch (estado) {
      case 'delivered':
        bg = AppColors.yellow.withValues(alpha: 0.2);
        fg = AppColors.black;
        break;
      case 'canceled':
        bg = AppColors.red.withValues(alpha: 0.15);
        fg = AppColors.red;
        break;
      case 'shipped':
      case 'approved':
        bg = AppColors.yellow.withValues(alpha: 0.1);
        fg = AppColors.yellowDark;
        break;
      default:
        bg = AppColors.gray.withValues(alpha: 0.15);
        fg = AppColors.gray;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _pageOffset > 0
              ? () {
                  setState(() => _pageOffset -= _pageSize);
                  _loadTable();
                }
              : null,
          icon: const Icon(Icons.chevron_left, size: 18),
          label: const Text('Anterior'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 40),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Página $_currentPage de $_totalPages',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _currentPage < _totalPages
              ? () {
                  setState(() => _pageOffset += _pageSize);
                  _loadTable();
                }
              : null,
          icon: const Icon(Icons.chevron_right, size: 18),
          label: const Text('Siguiente'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 40),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _MiniKpiCard extends StatelessWidget {
  const _MiniKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.gray,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
