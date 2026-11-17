class UserModel {
  final String id;
  final String nombre;
  final String email;
  final String? telefono;
  final String? direccion;
  final int? mesa;
  final List<String> roles;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    this.direccion,
    this.mesa,
    this.roles = const [],
    this.isAdmin = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rolesList = (json['roles'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final admin = json['isAdmin'] == true ||
        rolesList.contains('ROLE_ADMIN') ||
        rolesList.contains('ADMIN');

    return UserModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      telefono: json['telefono']?.toString(),
      direccion: json['direccion']?.toString(),
      mesa: json['mesa'] is num ? (json['mesa'] as num).toInt() : null,
      roles: rolesList,
      isAdmin: admin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'mesa': mesa,
      'roles': roles,
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
    List<String>? roles,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      mesa: mesa ?? this.mesa,
      roles: roles ?? this.roles,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
