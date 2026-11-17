class AdminUserModel {
  final String id;
  final String nombre;
  final String correo;
  final String rol;
  final bool esAdmin;

  AdminUserModel({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.esAdmin,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? 'Usuario').toString(),
      correo: (json['correo'] ?? '').toString(),
      rol: (json['rol'] ?? 'ROLE_USER').toString(),
      esAdmin: json['esAdmin'] == true,
    );
  }
}
