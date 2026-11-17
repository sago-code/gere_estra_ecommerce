import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pedido_models.dart';

/// Servicio para consumir pedidos del backend.
class PedidoService {
  static const String baseUrl = 'http://localhost:3000';
  final http.Client _client;

  PedidoService({http.Client? client}) : _client = client ?? http.Client();

  /// Obtiene pedidos paginados.
  Future<PedidosResponse> getPedidos({int limit = 50, int offset = 0}) async {
    // Cache-buster para evitar respuestas 304 sin cuerpo en Flutter web.
    final ts = DateTime.now().millisecondsSinceEpoch;
    final uri =
        Uri.parse('$baseUrl/pedidos?limit=$limit&offset=$offset&_t=$ts');
    final response = await _client
        .get(uri, headers: {'Content-Type': 'application/json', 'Cache-Control': 'no-cache'}).timeout(
              const Duration(seconds: 20),
            );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return PedidosResponse.fromJson(data);
    }
    throw Exception('Error al cargar pedidos (${response.statusCode}).');
  }
}
