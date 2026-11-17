import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/cliente_models.dart';
import '../services/cliente_service.dart';
import '../theme/app_theme.dart';

/// Pantalla de Clientes con KPIs, gráfico por ciudad y tabla paginada.
class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final ClienteService _service = ClienteService();

  List<Cliente> _kpiClientes = [];
  int _totalClientes = 0;
  bool _kpiLoading = true;
  String? _kpiError;

  List<Cliente> _tableClientes = [];
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
      final res = await _service.getClientes(limit: 200, offset: 0);
      if (mounted) {
        setState(() {
          _kpiClientes = res.items;
          _totalClientes = res.total;
          _kpiLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando KPIs de clientes: $e');
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
      final res = await _service.getClientes(
          limit: _pageSize, offset: _pageOffset);
      if (mounted) {
        setState(() {
          _tableClientes = res.items;
          _tableLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando tabla de clientes: $e');
      if (mounted) {
        setState(() {
          _tableError = e.toString();
          _tableLoading = false;
        });
      }
    }
  }

  // --- Cálculos de KPIs ---
  int get _activos => _kpiClientes.where((c) => c.estadoCliente).length;
  int get _inactivos => _kpiClientes.where((c) => !c.estadoCliente).length;
  int get _ciudadesDistintas =>
      _kpiClientes.map((c) => c.usuario.ciudad.id).toSet().length;

  Map<String, int> get _ciudadCounts {
    final map = <String, int>{};
    for (final c in _kpiClientes) {
      map[c.usuario.ciudad.nombre] = (map[c.usuario.ciudad.nombre] ?? 0) + 1;
    }
    return map;
  }

  String get _topCiudad {
    if (_ciudadCounts.isEmpty) return '-';
    final entry = _ciudadCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    return entry.key;
  }

  int get _totalPages => (_totalClientes / _pageSize).ceil();
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
            'Gestión de Clientes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total registrado en el sistema: $_totalClientes clientes',
            style: const TextStyle(color: AppColors.gray, fontSize: 14),
          ),
          if (_kpiError != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(_kpiError!),
          ],
          const SizedBox(height: 24),
          _buildKpiCards(),
          const SizedBox(height: 32),
          _buildSectionTitle('Top ciudades con más clientes'),
          const SizedBox(height: 16),
          _buildCiudadChart(),
          const SizedBox(height: 32),
          _buildSectionTitle('Listado de clientes'),
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
              title: 'Clientes (muestra)',
              value: '${_kpiClientes.length}',
              icon: Icons.people,
              accent: AppColors.yellow,
            ),
            _MiniKpiCard(
              title: 'Activos',
              value: '$_activos',
              icon: Icons.person,
              accent: AppColors.yellow,
            ),
            _MiniKpiCard(
              title: 'Inactivos',
              value: '$_inactivos',
              icon: Icons.person_off,
              accent: AppColors.red,
            ),
            _MiniKpiCard(
              title: 'Ciudades',
              value: '$_ciudadesDistintas',
              icon: Icons.location_city,
              accent: AppColors.yellow,
            ),
            _MiniKpiCard(
              title: '% Activos',
              value:
                  '${_kpiClientes.isEmpty ? 0 : ((_activos / _kpiClientes.length) * 100).toStringAsFixed(0)}%',
              icon: Icons.percent,
              accent: AppColors.yellow,
            ),
            _MiniKpiCard(
              title: '% Inactivos',
              value:
                  '${_kpiClientes.isEmpty ? 0 : ((_inactivos / _kpiClientes.length) * 100).toStringAsFixed(0)}%',
              icon: Icons.percent,
              accent: AppColors.red,
            ),
            _MiniKpiCard(
              title: 'Top ciudad',
              value: _topCiudad.length > 14
                  ? '${_topCiudad.substring(0, 14)}…'
                  : _topCiudad,
              icon: Icons.star,
              accent: AppColors.yellow,
            ),
            _MiniKpiCard(
              title: 'Clientes/ciudad',
              value: _ciudadesDistintas == 0
                  ? '0'
                  : (_kpiClientes.length / _ciudadesDistintas)
                      .toStringAsFixed(1),
              icon: Icons.bar_chart,
              accent: AppColors.yellow,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCiudadChart() {
    if (_kpiLoading || _kpiClientes.isEmpty) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final counts = _ciudadCounts;
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
                  '${topEntries[group.x].key}\n${rod.toY.toInt()} clientes',
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
    if (_tableClientes.isEmpty) {
      return const Center(child: Text('Sin clientes'));
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
            DataColumn(label: Text('Correo')),
            DataColumn(label: Text('Ciudad')),
            DataColumn(label: Text('Teléfono')),
            DataColumn(label: Text('Estado')),
          ],
          rows: _tableClientes.map((c) {
            return DataRow(
              cells: [
                DataCell(Text('#${c.id}')),
                DataCell(
                  SizedBox(
                    width: 180,
                    child: Text(
                      c.usuario.nombreCompleto,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 230,
                    child: Text(
                      c.usuario.correo,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(c.usuario.ciudad.nombre)),
                DataCell(Text('${c.usuario.telefono}')),
                DataCell(_buildEstadoBadge(c.estadoCliente)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(bool activo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: activo
            ? AppColors.yellow.withValues(alpha: 0.2)
            : AppColors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: activo ? AppColors.black : AppColors.red,
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
