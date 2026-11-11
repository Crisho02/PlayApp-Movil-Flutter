/// Reseña publicada por un cliente de PlayApp.
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
}

/// Mensaje enviado desde el formulario de contacto de PlayApp.
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
}
