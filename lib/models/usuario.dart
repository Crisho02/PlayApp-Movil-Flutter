import 'package:mongo_dart/mongo_dart.dart' as mongo;

/// Roles soportados por el sistema de autenticación de PlayApp.
enum RolUsuario {
  user('USER', 'Usuario', 'ROLE_USER'),
  admin('ADMIN', 'Administrador', 'ROLE_ADMIN');

  const RolUsuario(this.codigo, this.etiqueta, this.roleAuthority);

  final String codigo;
  final String etiqueta;
  final String roleAuthority;

  static RolUsuario fromString(dynamic value) {
    final str = '$value'.toUpperCase();
    if (str.contains('ADMIN')) {
      return RolUsuario.admin;
    }
    return RolUsuario.user;
  }
}

/// Modelo de usuario o entidad/restaurante registrado en PlayApp.
class Usuario {
  const Usuario({
    required this.id,
    required this.nombreCompleto,
    required this.correo,
    required this.password,
    required this.rol,
  });

  final String id;
  final String nombreCompleto;
  final String correo;
  final String password;
  final RolUsuario rol;

  Usuario copyWith({
    String? id,
    String? nombreCompleto,
    String? correo,
    String? password,
    RolUsuario? rol,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      correo: correo ?? this.correo,
      password: password ?? this.password,
      rol: rol ?? this.rol,
    );
  }

  /// Deserializa un documento de la colección `entidades`.
  factory Usuario.fromMongo(Map<String, dynamic> doc) {
    final rawId = doc['_id'];
    final id = rawId is mongo.ObjectId ? rawId.oid : '$rawId';

    return Usuario(
      id: id,
      nombreCompleto: doc['nombreCompleto']?.toString() ?? 'Usuario PlayApp',
      correo: doc['correo']?.toString() ?? '',
      password: doc['password']?.toString() ?? '',
      rol: RolUsuario.fromString(doc['rol']),
    );
  }

  /// Convierte el usuario a formato MongoDB compatible con Spring Boot.
  Map<String, dynamic> toMongo() {
    final doc = <String, dynamic>{
      'nombreCompleto': nombreCompleto,
      'correo': correo.toLowerCase().trim(),
      'password': password,
      'rol': rol.roleAuthority,
      '_class': 'com.proyecto.PlayApp.entity.Usuario',
    };

    if (id.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      doc['_id'] = mongo.ObjectId.fromHexString(id);
    } else {
      doc['_id'] = id;
    }

    return doc;
  }
}
