import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/kpi_models.dart';
import '../services/kpi_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// Pantalla principal del Dashboard con KPIs, gráfico y tabla.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.storage});

  final StorageService storage;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final KpiService _kpiService = KpiService();
  Future<KpisResponse>? _kpisFuture;

  @override
  void initState() {
    super.initState();
    _kpisFuture = _kpiService.getAllKpis();
  }

  Future<void> _refresh() async {
    setState(() {
      _kpisFuture = _kpiService.getAllKpis();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.red,
      child: FutureBuilder<KpisResponse>(
        future: _kpisFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Sin datos'));
          }

          final kpis = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, ${widget.storage.nombre ?? 'Administrador'}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.storage.correo ?? '',
                  style:
                      const TextStyle(color: AppColors.gray, fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildKpiCards(kpis),
                const SizedBox(height: 32),
                _buildSectionTitle('Productos más vendidos'),
                const SizedBox(height: 16),
                _buildBarChart(kpis.productosMasVendidos.productos),
                const SizedBox(height: 32),
                _buildSectionTitle('Detalle de productos'),
                const SizedBox(height: 16),
                _buildProductsTable(kpis.productosMasVendidos.productos),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            'No se pudieron cargar los KPIs',
            style: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(color: AppColors.gray, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refresh,
            child: const Text('Reintentar'),
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

  /// Tarjetas de los 3 KPIs principales.
  Widget _buildKpiCards(KpisResponse kpis) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWide ? 3 : 1,
          childAspectRatio: isWide ? 1.4 : 2.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _KpiCard(
              title: 'Ticket Promedio',
              value:
                  'R\$ ${kpis.ticketPromedio.ticketPromedio.toStringAsFixed(0)}',
              meta: 'Meta: R\$ ${kpis.ticketPromedio.meta.toStringAsFixed(0)}',
              cumplida: kpis.ticketPromedio.cumpleMeta,
              icon: Icons.attach_money,
              accent: AppColors.yellow,
              subtitle:
                  '${kpis.ticketPromedio.totalPagos} pagos · R\$ ${(kpis.ticketPromedio.totalVentas / 1000000).toStringAsFixed(1)}M ventas',
            ),
            _KpiCard(
              title: 'Ciclo de Entrega',
              value:
                  '${kpis.cicloEntrega.cicloPromedioDias.toStringAsFixed(1)} días',
              meta: 'Meta: ${kpis.cicloEntrega.meta.toStringAsFixed(0)} días',
              cumplida: kpis.cicloEntrega.cumpleMeta,
              icon: Icons.local_shipping,
              accent: AppColors.red,
              subtitle:
                  '${kpis.cicloEntrega.totalEntregados} entregados · ${kpis.cicloEntrega.maxDias.toStringAsFixed(0)} días máx.',
            ),
            _KpiCard(
              title: 'Producto Top',
              value: kpis.productosMasVendidos.productos.isNotEmpty
                  ? _truncate(kpis.productosMasVendidos.productos.first.productoNombre, 16)
                  : '-',
              meta: kpis.productosMasVendidos.productos.isNotEmpty
                  ? '${kpis.productosMasVendidos.productos.first.totalVendido} unidades'
                  : '',
              cumplida: true,
              icon: Icons.inventory_2,
              accent: AppColors.yellow,
              subtitle: kpis.productosMasVendidos.productos.isNotEmpty
                  ? 'R\$ ${kpis.productosMasVendidos.productos.first.ingresos.toStringAsFixed(0)} ingresos'
                  : '',
            ),
          ],
        );
      },
    );
  }

  String _truncate(String text, int max) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}...';
  }

  /// Gráfico de barras horizontales con fl_chart.
  Widget _buildBarChart(List<ProductoVendido> productos) {
    if (productos.isEmpty) {
      return const Center(child: Text('Sin datos de productos'));
    }
    final top = productos.take(6).toList();
    final maxValue =
        top.map((p) => p.totalVendido).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray.withValues(alpha: 0.3)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => AppColors.black,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final p = top[group.x];
                return BarTooltipItem(
                  '${p.totalVendido} uds',
                  const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= top.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        _truncate(top[index].productoNombre, 14),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.gray,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          barGroups: top.asMap().entries.map((entry) {
            final index = entry.key;
            final p = entry.value;
            final isTop = index == 0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: p.totalVendido.toDouble(),
                  color: isTop ? AppColors.red : AppColors.yellow,
                  width: 32,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Tabla detallada de productos más vendidos.
  Widget _buildProductsTable(List<ProductoVendido> productos) {
    if (productos.isEmpty) {
      return const Center(child: Text('Sin datos'));
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
          ),
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Producto')),
            DataColumn(label: Text('Categoría')),
            DataColumn(label: Text('Unidades')),
            DataColumn(label: Text('Ingresos (R\$)')),
          ],
          rows: productos.asMap().entries.map((entry) {
            final index = entry.key;
            final p = entry.value;
            final isTop = index == 0;
            return DataRow(
              color: isTop
                  ? WidgetStateProperty.all(
                      AppColors.yellow.withValues(alpha: 0.1))
                  : null,
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(Text(
                  p.productoNombre,
                  style: TextStyle(
                    fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                  ),
                )),
                DataCell(Text(p.categoria)),
                DataCell(Text('${p.totalVendido}')),
                DataCell(Text(p.ingresos.toStringAsFixed(2))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.meta,
    required this.cumplida,
    required this.icon,
    required this.accent,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String meta;
  final bool cumplida;
  final IconData icon;
  final Color accent;
  final String subtitle;

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.gray,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cumplida
                      ? AppColors.yellow.withValues(alpha: 0.2)
                      : AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  cumplida ? 'OK' : 'ALERTA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: cumplida ? AppColors.black : AppColors.red,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meta,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gray,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.gray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
