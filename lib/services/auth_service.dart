import 'dart:convert';
import 'package:http/http.dart' as http;

/// Modelo de la respuesta del login.
class LoginResponse {
  final String accessToken;
  final Usuario usuario;

  LoginResponse({required this.accessToken, required this.usuario});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String? ?? '',
      usuario: Usuario.fromJson(json['usuario'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class Usuario {
  final int id;
  final String nombres;
  final String apellidos;
  final String correo;
  final String rol;

  Usuario({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.correo,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
    );
  }

  String get nombreCompleto => '$nombres $apellidos'.trim();
}

/// Excepción de autenticación con mensaje amigable.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Servicio de autenticación contra el backend NestJS.
class AuthService {
  /// URL base del backend.
  /// En Android emulador usa http://10.0.2.2:3000 en lugar de localhost.
  static const String baseUrl = 'http://localhost:3000';

  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  Future<LoginResponse> login({
    required String correo,
    required String password,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/usuarios/login');

    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Cache-Control': 'no-cache'},
            body: jsonEncode({'correo': correo, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AuthException(
        'No se pudo conectar con el servidor.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return LoginResponse.fromJson(data);
    }

    if (response.statusCode == 401) {
      throw AuthException('Correo o contraseña incorrectos.');
    }

    if (response.statusCode == 403) {
      throw AuthException('No tienes permisos de administrador.');
    }

    String mensaje = 'Error al iniciar sesión (${response.statusCode}).';
    try {
      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      if (body['message'] != null) {
        mensaje = body['message'].toString();
      }
    } catch (_) {}
    throw AuthException(mensaje);
  }
}
