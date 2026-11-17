class UserModel {
  final String id;
  final String nombre;
  final String email;
  final String? telefono;
  final String? direccion;
  final int? mesa;
  final String rol;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    this.direccion,
    this.mesa,
    this.rol = 'ROLE_USER',
    this.isAdmin = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawRol = json['rol']?.toString() ??
        (json['roles'] is List && (json['roles'] as List).isNotEmpty
            ? (json['roles'] as List).first.toString()
            : 'ROLE_USER');

    final admin = json['esAdmin'] == true ||
        json['isAdmin'] == true ||
        rawRol.toUpperCase().contains('ADMIN');

    final name = json['nombreCompleto']?.toString() ??
        json['nombre']?.toString() ??
        'Usuario PlayApp';

    final mail = json['correo']?.toString() ??
        json['email']?.toString() ??
        '';

    return UserModel(
      id: json['id']?.toString() ?? '',
      nombre: name,
      email: mail,
      telefono: json['telefono']?.toString(),
      direccion: json['direccion']?.toString(),
      mesa: json['mesa'] is num ? (json['mesa'] as num).toInt() : null,
      rol: rawRol,
      isAdmin: admin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreCompleto': nombre,
      'nombre': nombre,
      'correo': email,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'mesa': mesa,
      'rol': rol,
      'esAdmin': isAdmin,
      'isAdmin': isAdmin,
    };
  }

  UserModel copyWith({
    String? id,
    String? nombre,
    String? email,
    String? telefono,
    String? direccion,
    int? mesa,
    String? rol,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      mesa: mesa ?? this.mesa,
      rol: rol ?? this.rol,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
