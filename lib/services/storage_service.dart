import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para almacenar y recuperar el token JWT y datos de sesión.
class StorageService {
  static const String _tokenKey = 'access_token';
  static const String _usuarioKey = 'usuario_nombre';
  static const String _correoKey = 'usuario_correo';
  static const String _rolKey = 'usuario_rol';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Future<void> saveSession({
    required String token,
    required String nombre,
    required String correo,
    required String rol,
  }) async {
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_usuarioKey, nombre);
    await _prefs.setString(_correoKey, correo);
    await _prefs.setString(_rolKey, rol);
  }

  String? get token => _prefs.getString(_tokenKey);
  String? get nombre => _prefs.getString(_usuarioKey);
  String? get correo => _prefs.getString(_correoKey);
  String? get rol => _prefs.getString(_rolKey);

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  Future<void> clear() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_usuarioKey);
    await _prefs.remove(_correoKey);
    await _prefs.remove(_rolKey);
  }
}
