class ReviewModel {
  final String id;
  final String nombreCliente;
  final int calificacion;
  final String comentario;
  final String fechaFormateada;
  final DateTime? fechaOriginal;

  ReviewModel({
    required this.id,
    required this.nombreCliente,
    required this.calificacion,
    required this.comentario,
    required this.fechaFormateada,
    this.fechaOriginal,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final rawName = json['nombre']?.toString() ??
        json['nombreCliente']?.toString() ??
        'Cliente PlayApp';

    final rawRating = json['valoracion'] ?? json['calificacion'] ?? 5;
    final ratingInt = (rawRating is num) ? rawRating.toInt() : 5;

    final rawComment = json['comentario']?.toString() ?? '';

    final rawDate = json['fecha']?.toString() ?? '';
    DateTime? dt;
    String formattedDate = rawDate;

    if (rawDate.isNotEmpty) {
      try {
        dt = DateTime.tryParse(rawDate);
        if (dt != null) {
          // Formateo en español legible: ej. "22 de mayo de 2026, 4:45 p. m."
          formattedDate = _formatSpanishDate(dt.toLocal());
        }
      } catch (_) {}
    }

    return ReviewModel(
      id: json['id']?.toString() ?? '',
      nombreCliente: rawName,
      calificacion: ratingInt,
      comentario: rawComment,
      fechaFormateada: formattedDate.isNotEmpty ? formattedDate : 'Reciente',
      fechaOriginal: dt,
    );
  }

  static String _formatSpanishDate(DateTime date) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;

    final hour12 = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'p. m.' : 'a. m.';

    return '$day de $month de $year, $hour12:$minute $period';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombreCliente,
      'nombreCliente': nombreCliente,
      'valoracion': calificacion,
      'calificacion': calificacion,
      'comentario': comentario,
      'fecha': fechaOriginal?.toIso8601String() ?? fechaFormateada,
    };
  }
}
