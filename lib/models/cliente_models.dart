/// Modelos para el endpoint GET /clientes.
library;

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class CiudadUsuario {
  final int id;
  final String nombre;

  CiudadUsuario({required this.id, required this.nombre});

  factory CiudadUsuario.fromJson(Map<String, dynamic> json) {
    return CiudadUsuario(
      id: _toInt(json['id']),
      nombre: json['nombre'] as String? ?? '',
    );
  }
}

class RolUsuario {
  final int id;
  final String rolName;

  RolUsuario({required this.id, required this.rolName});

  factory RolUsuario.fromJson(Map<String, dynamic> json) {
    return RolUsuario(
      id: _toInt(json['id']),
      rolName: json['rol_name'] as String? ?? '',
    );
  }
}

class UsuarioCliente {
  final int id;
  final String nombres;
  final String apellidos;
  final CiudadUsuario ciudad;
  final int telefono;
  final String correo;
  final RolUsuario rol;

  UsuarioCliente({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.ciudad,
    required this.telefono,
    required this.correo,
    required this.rol,
  });

  factory UsuarioCliente.fromJson(Map<String, dynamic> json) {
    return UsuarioCliente(
      id: _toInt(json['id']),
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      ciudad: CiudadUsuario.fromJson(
          json['ciudad'] as Map<String, dynamic>? ?? {}),
      telefono: _toInt(json['telefono']),
      correo: json['correo'] as String? ?? '',
      rol: RolUsuario.fromJson(json['rol'] as Map<String, dynamic>? ?? {}),
    );
  }

  String get nombreCompleto => '$nombres $apellidos'.trim();
}

class Cliente {
  final int id;
  final UsuarioCliente usuario;
  final bool estadoCliente;

  Cliente({
    required this.id,
    required this.usuario,
    required this.estadoCliente,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: _toInt(json['id']),
      usuario: UsuarioCliente.fromJson(
          json['usuario'] as Map<String, dynamic>? ?? {}),
      estadoCliente: json['estado_cliente'] as bool? ?? true,
    );
  }

  String get estadoLabel => estadoCliente ? 'Activo' : 'Inactivo';
}

class ClientesResponse {
  final List<Cliente> items;
  final int total;
  final int limit;
  final int offset;

  ClientesResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory ClientesResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = json['items'] as List<dynamic>? ?? [];
    return ClientesResponse(
      items: raw
          .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: _toInt(json['total']),
      limit: _toInt(json['limit']),
      offset: _toInt(json['offset']),
    );
  }
}
