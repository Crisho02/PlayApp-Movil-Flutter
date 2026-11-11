/// Roles soportados por el sistema de autenticación de PlayApp.
enum RolUsuario {
  user('USER', 'Usuario'),
  admin('ADMIN', 'Administrador');

  const RolUsuario(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;
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
}
