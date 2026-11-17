/// Modelos para el endpoint GET /pedidos.
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

class UsuarioPedido {
  final int id;
  final String nombres;
  final String apellidos;
  final String correo;

  UsuarioPedido({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.correo,
  });

  factory UsuarioPedido.fromJson(Map<String, dynamic> json) {
    return UsuarioPedido(
      id: _toInt(json['id']),
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
    );
  }

  String get nombreCompleto => '$nombres $apellidos'.trim();
}

class ClientePedido {
  final int id;
  final UsuarioPedido usuario;
  final bool estadoCliente;

  ClientePedido({
    required this.id,
    required this.usuario,
    required this.estadoCliente,
  });

  factory ClientePedido.fromJson(Map<String, dynamic> json) {
    return ClientePedido(
      id: _toInt(json['id']),
      usuario: UsuarioPedido.fromJson(
          json['usuario'] as Map<String, dynamic>? ?? {}),
      estadoCliente: json['estado_cliente'] as bool? ?? true,
    );
  }
}

class EstadoPedido {
  final int id;
  final String nombreEstado;

  EstadoPedido({required this.id, required this.nombreEstado});

  factory EstadoPedido.fromJson(Map<String, dynamic> json) {
    return EstadoPedido(
      id: _toInt(json['id']),
      nombreEstado: json['nombre_estado'] as String? ?? '',
    );
  }
}

class MetodoPago {
  final int id;
  final String nombreMetodo;

  MetodoPago({required this.id, required this.nombreMetodo});

  factory MetodoPago.fromJson(Map<String, dynamic> json) {
    return MetodoPago(
      id: _toInt(json['id']),
      nombreMetodo: json['nombre_metodo'] as String? ?? '',
    );
  }
}

class PagoPedido {
  final int id;
  final DateTime fechaPago;
  final double valorPago;
  final MetodoPago metodoPago;

  PagoPedido({
    required this.id,
    required this.fechaPago,
    required this.valorPago,
    required this.metodoPago,
  });

  factory PagoPedido.fromJson(Map<String, dynamic> json) {
    return PagoPedido(
      id: _toInt(json['id']),
      fechaPago:
          DateTime.tryParse(json['fecha_pago'] as String? ?? '') ??
          DateTime.now(),
      valorPago: _toDouble(json['valor_pago']),
      metodoPago: MetodoPago.fromJson(
          json['metodo_pago'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class Pedido {
  final int id;
  final DateTime createdAt;
  final ClientePedido cliente;
  final EstadoPedido estadoPedido;
  final bool estaPagado;
  final PagoPedido? pago;
  final DateTime fechaEntregaEstimada;
  final DateTime? fechaEntregaReal;

  Pedido({
    required this.id,
    required this.createdAt,
    required this.cliente,
    required this.estadoPedido,
    required this.estaPagado,
    required this.pago,
    required this.fechaEntregaEstimada,
    required this.fechaEntregaReal,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: _toInt(json['id']),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      cliente: ClientePedido.fromJson(
          json['cliente'] as Map<String, dynamic>? ?? {}),
      estadoPedido: EstadoPedido.fromJson(
          json['estado_pedido'] as Map<String, dynamic>? ?? {}),
      estaPagado: json['esta_pagado'] as bool? ?? false,
      pago: json['pago'] != null
          ? PagoPedido.fromJson(json['pago'] as Map<String, dynamic>)
          : null,
      fechaEntregaEstimada: DateTime.tryParse(
              json['fecha_entrega_estimada'] as String? ?? '') ??
          DateTime.now(),
      fechaEntregaReal: json['fecha_entrega_real'] != null
          ? DateTime.tryParse(json['fecha_entrega_real'] as String)
          : null,
    );
  }

  double get valor => pago?.valorPago ?? 0;
  String get estadoLabel => estadoPedido.nombreEstado;
}

class PedidosResponse {
  final List<Pedido> items;
  final int total;
  final int limit;
  final int offset;

  PedidosResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory PedidosResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = json['items'] as List<dynamic>? ?? [];
    return PedidosResponse(
      items: raw
          .map((e) => Pedido.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: _toInt(json['total']),
      limit: _toInt(json['limit']),
      offset: _toInt(json['offset']),
    );
  }
}
