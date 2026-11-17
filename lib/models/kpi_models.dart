/// Modelos para la respuesta del endpoint GET /kpis.
library;

/// Convierte un valor que puede ser [num] o [String] a [double].
/// MySQL serializa los DECIMAL como String, así que hay que parsearlos.
double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

/// Convierte un valor que puede ser [num] o [String] a [int].
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class TicketPromedio {
  final String kpi;
  final String formula;
  final int totalPagos;
  final double ticketPromedio;
  final double totalVentas;
  final double meta;

  TicketPromedio({
    required this.kpi,
    required this.formula,
    required this.totalPagos,
    required this.ticketPromedio,
    required this.totalVentas,
    required this.meta,
  });

  factory TicketPromedio.fromJson(Map<String, dynamic> json) {
    return TicketPromedio(
      kpi: json['kpi'] as String? ?? '',
      formula: json['formula'] as String? ?? '',
      totalPagos: _toInt(json['total_pagos']),
      ticketPromedio: _toDouble(json['ticket_promedio']),
      totalVentas: _toDouble(json['total_ventas']),
      meta: _toDouble(json['meta']),
    );
  }

  bool get cumpleMeta => ticketPromedio >= meta;
}

class CicloEntrega {
  final String kpi;
  final String formula;
  final int totalEntregados;
  final double cicloPromedioDias;
  final double minDias;
  final double maxDias;
  final double meta;

  CicloEntrega({
    required this.kpi,
    required this.formula,
    required this.totalEntregados,
    required this.cicloPromedioDias,
    required this.minDias,
    required this.maxDias,
    required this.meta,
  });

  factory CicloEntrega.fromJson(Map<String, dynamic> json) {
    return CicloEntrega(
      kpi: json['kpi'] as String? ?? '',
      formula: json['formula'] as String? ?? '',
      totalEntregados: _toInt(json['total_entregados']),
      cicloPromedioDias: _toDouble(json['ciclo_promedio_dias']),
      minDias: _toDouble(json['min_dias']),
      maxDias: _toDouble(json['max_dias']),
      meta: _toDouble(json['meta']),
    );
  }

  bool get cumpleMeta => cicloPromedioDias <= meta;
}

class ProductoVendido {
  final int productoId;
  final String productoNombre;
  final String categoria;
  final int totalVendido;
  final double ingresos;

  ProductoVendido({
    required this.productoId,
    required this.productoNombre,
    required this.categoria,
    required this.totalVendido,
    required this.ingresos,
  });

  factory ProductoVendido.fromJson(Map<String, dynamic> json) {
    return ProductoVendido(
      productoId: _toInt(json['producto_id']),
      productoNombre: json['producto_nombre'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      totalVendido: _toInt(json['total_vendido']),
      ingresos: _toDouble(json['ingresos']),
    );
  }
}

class ProductosMasVendidos {
  final String kpi;
  final String formula;
  final int limit;
  final List<ProductoVendido> productos;

  ProductosMasVendidos({
    required this.kpi,
    required this.formula,
    required this.limit,
    required this.productos,
  });

  factory ProductosMasVendidos.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = json['productos'] as List<dynamic>? ?? [];
    return ProductosMasVendidos(
      kpi: json['kpi'] as String? ?? '',
      formula: json['formula'] as String? ?? '',
      limit: _toInt(json['limit']),
      productos: raw
          .map((e) => ProductoVendido.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class KpisResponse {
  final TicketPromedio ticketPromedio;
  final CicloEntrega cicloEntrega;
  final ProductosMasVendidos productosMasVendidos;

  KpisResponse({
    required this.ticketPromedio,
    required this.cicloEntrega,
    required this.productosMasVendidos,
  });

  factory KpisResponse.fromJson(Map<String, dynamic> json) {
    return KpisResponse(
      ticketPromedio: TicketPromedio.fromJson(
          json['ticket_promedio'] as Map<String, dynamic>? ?? {}),
      cicloEntrega: CicloEntrega.fromJson(
          json['ciclo_entrega'] as Map<String, dynamic>? ?? {}),
      productosMasVendidos: ProductosMasVendidos.fromJson(
          json['productos_mas_vendidos'] as Map<String, dynamic>? ?? {}),
    );
  }
}
