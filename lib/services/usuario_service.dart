import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio para operaciones de usuario: crear admin y obtener ciudades.
class UsuarioService {
  static const String baseUrl = 'http://localhost:3000';
  final http.Client _client;

  UsuarioService({http.Client? client}) : _client = client ?? http.Client();

  /// Crea un nuevo usuario administrador.
  Future<Map<String, dynamic>> createAdmin({
    required String nombres,
    required String apellidos,
    required int ciudadId,
    required int telefono,
    required String correo,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/usuarios/admin');
    final body = jsonEncode({
      'nombres': nombres,
      'apellidos': apellidos,
      'ciudad_id': ciudadId,
      'telefono': telefono,
      'correo': correo,
      'password': password,
    });

    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Cache-Control': 'no-cache',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    String mensaje = 'Error al crear administrador (${response.statusCode}).';
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        if (msg is List) {
          mensaje = msg.join(', ');
        } else {
          mensaje = msg.toString();
        }
      }
    } catch (_) {}
    throw Exception(mensaje);
  }

  /// Obtiene el catálogo de ciudades.
  Future<List<Ciudad>> getCiudades() async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final uri = Uri.parse('$baseUrl/ciudades?_t=$ts');

    final response = await _client
        .get(uri, headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        })
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Ciudad.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Error al cargar ciudades (${response.statusCode}).');
  }
}

class Ciudad {
  final int id;
  final String nombre;

  Ciudad({required this.id, required this.nombre});

  factory Ciudad.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    return Ciudad(
      id: toInt(json['id']),
      nombre: json['nombre'] as String? ?? '',
    );
  }
}
