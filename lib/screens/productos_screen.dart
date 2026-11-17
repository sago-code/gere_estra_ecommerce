import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/producto_models.dart';
import '../services/producto_service.dart';
import '../theme/app_theme.dart';

/// Pantalla de Productos con KPIs, gráfico por categoría y tabla paginada.
class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ProductoService _service = ProductoService();

  List<Producto> _kpiProductos = [];
  int _totalProductos = 0;
  bool _kpiLoading = true;
  String? _kpiError;

  List<Producto> _tableProductos = [];
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
      final res = await _service.getProductos(limit: 200, offset: 0);
      if (mounted) {
        setState(() {
          _kpiProductos = res.items;
          _totalProductos = res.total;
          _kpiLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando KPIs de productos: $e');
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
      final res = await _service.getProductos(
          limit: _pageSize, offset: _pageOffset);
      if (mounted) {
        setState(() {
          _tableProductos = res.items;
          _tableLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando tabla de productos: $e');
      if (mounted) {
        setState(() {
          _tableError = e.toString();
          _tableLoading = false;
        });
      }
    }
  }

  // --- Cálculos de KPIs ---
  int get _stockTotal => _kpiProductos.fold(0, (sum, p) => sum + p.stock);
  double get _precioPromedio => _kpiProductos.isEmpty
      ? 0
      : _kpiProductos.fold<double>(0, (sum, p) => sum + p.precio) /
          _kpiProductos.length;
  int get _agotados => _kpiProductos.where((p) => p.stock == 0).length;
  int get _stockBajo =>
      _kpiProductos.where((p) => p.stock > 0 && p.stock < 50).length;
  int get _categoriasDistintas =>
      _kpiProductos.map((p) => p.categoria.id).toSet().length;
  Producto get _masCaro => _kpiProductos.reduce(
      (Producto a, Producto b) => a.precio > b.precio ? a : b);

  Map<String, int> get _categoriaCounts {
    final map = <String, int>{};
    for (final p in _kpiProductos) {
      map[p.categoria.nombre] = (map[p.categoria.nombre] ?? 0) + 1;
    }
    return map;
  }

  int get _totalPages => (_totalProductos / _pageSize).ceil();
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
            'Catálogo de Productos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total registrado en el sistema: $_totalProductos productos',
            style: const TextStyle(color: AppColors.gray, fontSize: 14),
          ),
          if (_kpiError != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(_kpiError!),
          ],
          const SizedBox(height: 24),
          _buildKpiCards(),
          const SizedBox(height: 32),
          _buildSectionTitle('Distribución por categoría (Top 8)'),
          const SizedBox(height: 16),
          _buildCategoriaChart(),
          const SizedBox(height: 32),
          _buildSectionTitle('Listado de productos'),
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
              title: 'Productos (muestra)',
              value: '${_kpiProductos.length}',
              icon: Icons.inventory_2,
              accent: AppColors.yellow,
            ),
            _MiniKpiCard(
              title: 'Stock total',
              value: '$_stockTotal',
              icon: Icons.warehouse,
              accent: AppColors.yellow,
            ),
            _MiniKpiCard(
              title: 'Precio promedio',
              value: 'R\$ ${_precioPromedio.toStringAsFixed(2)}',
              icon: Icons.sell,
              accent: AppColors.yellow,
            ),
            _MiniKpiCard(
              title: 'Categorías',
              value: '$_categoriasDistintas',
              icon: Icons.category,
              accent: AppColors.yellow,
            ),
            _MiniKpiCard(
              title: 'Agotados',
              value: '$_agotados',
              icon: Icons.remove_shopping_cart,
              accent: AppColors.red,
            ),
            _MiniKpiCard(
              title: 'Stock bajo (<50)',
              value: '$_stockBajo',
              icon: Icons.warning_amber,
              accent: AppColors.red,
            ),
            _MiniKpiCard(
              title: '% En stock',
              value:
                  '${_kpiProductos.isEmpty ? 0 : (((_kpiProductos.length - _agotados) / _kpiProductos.length) * 100).toStringAsFixed(0)}%',
              icon: Icons.check_circle,
              accent: AppColors.yellow,
            ),
            _MiniKpiCard(
              title: 'Más caro',
              value: 'R\$ ${_masCaro.precio.toStringAsFixed(0)}',
              icon: Icons.trending_up,
              accent: AppColors.yellow,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoriaChart() {
    if (_kpiLoading || _kpiProductos.isEmpty) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final counts = _categoriaCounts;
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(8).toList();

    final palette = [
      AppColors.red,
      AppColors.yellow,
      AppColors.black,
      AppColors.redDark,
      AppColors.yellowDark,
      AppColors.blackSoft,
      AppColors.gray,
      AppColors.red.withValues(alpha: 0.6),
    ];

    return Container(
      height: 340,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray.withValues(alpha: 0.3)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: topEntries.first.value.toDouble() * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${topEntries[group.x].key}\n${rod.toY.toInt()} productos',
                  const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
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
                  final idx = value.toInt();
                  if (idx < 0 || idx >= topEntries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      topEntries[idx].key.length > 12
                          ? '${topEntries[idx].key.substring(0, 12)}…'
                          : topEntries[idx].key,
                      style: const TextStyle(fontSize: 9, color: AppColors.black),
                      textAlign: TextAlign.center,
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
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.gray.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: topEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final color = palette[index % palette.length];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.value.toDouble(),
                  color: color,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
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
    if (_tableProductos.isEmpty) {
      return const Center(child: Text('Sin productos'));
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
            DataColumn(label: Text('Nombre')),
            DataColumn(label: Text('Categoría')),
            DataColumn(label: Text('Stock')),
            DataColumn(label: Text('Precio')),
            DataColumn(label: Text('Estado')),
          ],
          rows: _tableProductos.map((p) {
            return DataRow(
              cells: [
                DataCell(Text('#${p.id}')),
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(
                      p.nombre,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(p.categoria.nombre)),
                DataCell(Text('${p.stock}')),
                DataCell(Text('R\$ ${p.precio.toStringAsFixed(2)}')),
                DataCell(_buildStockBadge(p.stockStatus)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStockBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'Agotado':
        bg = AppColors.red.withValues(alpha: 0.15);
        fg = AppColors.red;
        break;
      case 'Bajo':
        bg = AppColors.yellow.withValues(alpha: 0.2);
        fg = AppColors.black;
        break;
      case 'Medio':
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
        status,
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
          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 40)),
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
          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 40)),
        ),
      ],
    );
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
