/// Modelos para el endpoint GET /productos.
library;

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class CategoriaProducto {
  final int id;
  final String nombre;
  final String descripcion;

  CategoriaProducto({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  factory CategoriaProducto.fromJson(Map<String, dynamic> json) {
    return CategoriaProducto(
      id: _toInt(json['id']),
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
    );
  }
}

class Producto {
  final int id;
  final String nombre;
  final String descripcion;
  final CategoriaProducto categoria;
  final int stock;
  final double precio;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.stock,
    required this.precio,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: _toInt(json['id']),
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      categoria: CategoriaProducto.fromJson(
          json['categoria'] as Map<String, dynamic>? ?? {}),
      stock: _toInt(json['stock']),
      precio: _toDouble(json['precio']),
    );
  }

  /// Clasificación de stock para KPIs.
  String get stockStatus {
    if (stock == 0) return 'Agotado';
    if (stock < 50) return 'Bajo';
    if (stock < 200) return 'Medio';
    return 'Alto';
  }
}

class ProductosResponse {
  final List<Producto> items;
  final int total;
  final int limit;
  final int offset;

  ProductosResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory ProductosResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = json['items'] as List<dynamic>? ?? [];
    return ProductosResponse(
      items: raw
          .map((e) => Producto.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: _toInt(json['total']),
      limit: _toInt(json['limit']),
      offset: _toInt(json['offset']),
    );
  }
}
