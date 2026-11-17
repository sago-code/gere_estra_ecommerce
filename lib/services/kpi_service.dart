import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/kpi_models.dart';

/// Servicio para consumir los KPIs del backend.
class KpiService {
  static const String baseUrl = 'http://localhost:3000';
  final http.Client _client;

  KpiService({http.Client? client}) : _client = client ?? http.Client();

  /// Obtiene los 3 KPIs en una sola llamada.
  Future<KpisResponse> getAllKpis() async {
    // Cache-buster para evitar respuestas 304 sin cuerpo en Flutter web.
    final uri = Uri.parse('$baseUrl/kpis?_t=${DateTime.now().millisecondsSinceEpoch}');
    final response = await _client
        .get(uri, headers: {'Content-Type': 'application/json', 'Cache-Control': 'no-cache'}).timeout(
              const Duration(seconds: 15),
            );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return KpisResponse.fromJson(data);
    }
    throw Exception('Error al cargar KPIs (${response.statusCode}).');
  }
}
