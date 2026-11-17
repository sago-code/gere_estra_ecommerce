import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cliente_models.dart';

/// Servicio para consumir clientes del backend.
class ClienteService {
  static const String baseUrl = 'http://localhost:3000';
  final http.Client _client;

  ClienteService({http.Client? client}) : _client = client ?? http.Client();

  Future<ClientesResponse> getClientes({
    int limit = 100,
    int offset = 0,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final uri = Uri.parse(
      '$baseUrl/clientes?limit=$limit&offset=$offset&_t=$ts',
    );

    final response = await _client
        .get(uri, headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        })
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ClientesResponse.fromJson(data as Map<String, dynamic>);
    }
    throw Exception(
        'Error al cargar clientes (${response.statusCode}): ${response.body}');
  }
}
