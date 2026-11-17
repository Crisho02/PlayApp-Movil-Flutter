class ReviewModel {
  final String id;
  final String nombreCliente;
  final int calificacion;
  final String comentario;
  final String fecha;

  ReviewModel({
    required this.id,
    required this.nombreCliente,
    required this.calificacion,
    required this.comentario,
    required this.fecha,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      nombreCliente: json['nombreCliente']?.toString() ?? 'Cliente PlayApp',
      calificacion: (json['calificacion'] is num)
          ? (json['calificacion'] as num).toInt()
          : 5,
      comentario: json['comentario']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreCliente': nombreCliente,
      'calificacion': calificacion,
      'comentario': comentario,
      'fecha': fecha,
    };
  }
}
