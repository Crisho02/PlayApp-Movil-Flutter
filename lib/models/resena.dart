import 'package:mongo_dart/mongo_dart.dart' as mongo;

/// Reseña publicada por un cliente de PlayApp (`reseñas`).
class Resena {
  const Resena({
    required this.id,
    required this.nombre,
    required this.valoracion,
    required this.comentario,
    required this.fecha,
  });

  final String id;
  final String nombre;
  final int valoracion;
  final String comentario;
  final DateTime fecha;

  factory Resena.fromMongo(Map<String, dynamic> doc) {
    final rawId = doc['_id'];
    final id = rawId is mongo.ObjectId ? rawId.oid : '$rawId';

    final rawFecha = doc['fecha'];
    final fecha = rawFecha is DateTime
        ? rawFecha
        : (DateTime.tryParse('$rawFecha') ?? DateTime.now());

    return Resena(
      id: id,
      nombre: doc['nombre']?.toString() ?? 'Cliente PlayApp',
      valoracion: (doc['valoracion'] as num?)?.toInt() ?? 5,
      comentario: doc['comentario']?.toString() ?? '',
      fecha: fecha,
    );
  }

  Map<String, dynamic> toMongo() {
    final doc = <String, dynamic>{
      'nombre': nombre,
      'valoracion': valoracion,
      'comentario': comentario,
      'fecha': fecha,
      '_class': 'com.proyecto.PlayApp.entity.Resena',
    };
    if (id.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      doc['_id'] = mongo.ObjectId.fromHexString(id);
    } else {
      doc['_id'] = id;
    }
    return doc;
  }
}

/// Mensaje enviado desde el formulario de contacto de PlayApp (`mensajes_contacto`).
class MensajeContacto {
  const MensajeContacto({
    required this.id,
    required this.nombre,
    required this.email,
    required this.asunto,
    required this.mensaje,
    required this.fecha,
  });

  final String id;
  final String nombre;
  final String email;
  final String asunto;
  final String mensaje;
  final DateTime fecha;

  factory MensajeContacto.fromMongo(Map<String, dynamic> doc) {
    final rawId = doc['_id'];
    final id = rawId is mongo.ObjectId ? rawId.oid : '$rawId';

    final rawFecha = doc['fechaEnvio'] ?? doc['fecha'];
    final fecha = rawFecha is DateTime
        ? rawFecha
        : (DateTime.tryParse('$rawFecha') ?? DateTime.now());

    return MensajeContacto(
      id: id,
      nombre: doc['nombre']?.toString() ?? '',
      email: doc['email']?.toString() ?? '',
      asunto: doc['asunto']?.toString() ?? '',
      mensaje: doc['mensaje']?.toString() ?? '',
      fecha: fecha,
    );
  }

  Map<String, dynamic> toMongo() {
    final doc = <String, dynamic>{
      'nombre': nombre,
      'email': email,
      'asunto': asunto,
      'mensaje': mensaje,
      'fechaEnvio': fecha,
      '_class': 'com.proyecto.PlayApp.entity.Mensaje',
    };
    if (id.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      doc['_id'] = mongo.ObjectId.fromHexString(id);
    } else {
      doc['_id'] = id;
    }
    return doc;
  }
}
