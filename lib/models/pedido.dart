import 'package:flutter/material.dart';
import '../theme/playapp_theme.dart';

/// Estado operativo del pedido (0: Recibido, 1: En preparación, 2: Terminado).
enum EstadoPedido {
  recibido(0, 'Recibido', PlayAppColors.primaryBlue),
  enPreparacion(1, 'En preparación', PlayAppColors.warningAmber),
  terminado(2, 'Terminado', PlayAppColors.successGreen);

  const EstadoPedido(this.codigo, this.etiqueta, this.color);

  final int codigo;
  final String etiqueta;
  final Color color;

  Color get textColor =>
      this == EstadoPedido.enPreparacion ? const Color(0xFF1F2937) : Colors.white;
}

/// Estado del pago asociado al pedido (0: En espera, 1: Terminado, 2: Cancelado).
enum EstadoPago {
  enEspera(0, 'En espera', PlayAppColors.infoCyan),
  terminado(1, 'Terminado', PlayAppColors.successGreen),
  cancelado(2, 'Cancelado', PlayAppColors.dangerRed);

  const EstadoPago(this.codigo, this.etiqueta, this.color);

  final int codigo;
  final String etiqueta;
  final Color color;

  Color get textColor =>
      this == EstadoPago.enEspera ? const Color(0xFF1F2937) : Colors.white;
}

/// Línea de producto incluida dentro de un pedido confirmado.
class PedidoItem {
  const PedidoItem({
    required this.productoId,
    required this.nombre,
    required this.precioUnitario,
    required this.cantidad,
    required this.entidadNombre,
  });

  final String productoId;
  final String nombre;
  final double precioUnitario;
  final int cantidad;
  final String entidadNombre;

  double get subtotal => precioUnitario * cantidad;
}

/// Datos de geolocalización y entrega en playa del pedido.
class Envio {
  const Envio({
    required this.latitud,
    required this.longitud,
    required this.direccion,
    required this.mesaCarpa,
    required this.descripcion,
  });

  final double latitud;
  final double longitud;
  final String direccion;
  final int mesaCarpa;
  final String descripcion;
}

/// Información de pago vinculada al pedido.
class Pago {
  const Pago({
    required this.metodo,
    required this.valor,
    required this.estado,
    required this.fecha,
  });

  final String metodo;
  final double valor;
  final EstadoPago estado;
  final DateTime fecha;

  Pago copyWith({EstadoPago? estado, String? metodo, DateTime? fecha}) {
    return Pago(
      metodo: metodo ?? this.metodo,
      valor: valor,
      estado: estado ?? this.estado,
      fecha: fecha ?? this.fecha,
    );
  }
}

/// Pedido completo realizado en PlayApp.
class Pedido {
  const Pedido({
    required this.id,
    required this.clienteCorreo,
    required this.clienteNombre,
    required this.estado,
    required this.total,
    required this.timestamp,
    required this.items,
    required this.pago,
    required this.envio,
  });

  final String id;
  final String clienteCorreo;
  final String clienteNombre;
  final EstadoPedido estado;
  final double total;
  final DateTime timestamp;
  final List<PedidoItem> items;
  final Pago pago;
  final Envio envio;

  Pedido copyWith({
    EstadoPedido? estado,
    Pago? pago,
  }) {
    return Pedido(
      id: id,
      clienteCorreo: clienteCorreo,
      clienteNombre: clienteNombre,
      estado: estado ?? this.estado,
      total: total,
      timestamp: timestamp,
      items: items,
      pago: pago ?? this.pago,
      envio: envio,
    );
  }
}
