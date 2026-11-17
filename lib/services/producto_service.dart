import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/producto_models.dart';

/// Servicio para consumir productos del backend.
class ProductoService {
  static const String baseUrl = 'http://localhost:3000';
  final http.Client _client;

  ProductoService({http.Client? client}) : _client = client ?? http.Client();

  Future<ProductosResponse> getProductos({
    int limit = 100,
    int offset = 0,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final uri = Uri.parse(
      '$baseUrl/productos?limit=$limit&offset=$offset&_t=$ts',
    );

    final response = await _client
        .get(uri, headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        })
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProductosResponse.fromJson(data as Map<String, dynamic>);
    }
    throw Exception(
        'Error al cargar productos (${response.statusCode}): ${response.body}');
  }

  Future<List<CategoriaProducto>> getCategorias() async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final uri = Uri.parse('$baseUrl/categorias?_t=$ts');

    final response = await _client
        .get(uri, headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        })
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => CategoriaProducto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
        'Error al cargar categorías (${response.statusCode}): ${response.body}');
  }
}
