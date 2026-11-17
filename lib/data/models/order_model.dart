import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import 'cart_item_model.dart';

class OrderModel {
  final String id;
  final String fecha;
  final double total;
  final double subtotal;
  final double costoEnvio;
  final String estadoPedido;
  final String estadoPago;
  final String metodoPago;
  final String? direccion;
  final String? barrio;
  final int? carpa;
  final String? telefono;
  final String? clienteNombre;
  final String? clienteEmail;
  final List<CartItemModel> items;

  OrderModel({
    required this.id,
    required this.fecha,
    required this.total,
    this.subtotal = 0.0,
    this.costoEnvio = 5000.0,
    required this.estadoPedido,
    required this.estadoPago,
    required this.metodoPago,
    this.direccion,
    this.barrio,
    this.carpa,
    this.telefono,
    this.clienteNombre,
    this.clienteEmail,
    this.items = const [],
  });

  String get shortId => id.length > 8 ? id.substring(0, 8) : id;
  String get displayCode => '#$shortId';

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ??
        json['carrito'] as List<dynamic>? ??
        [];

    final parsedItems = rawItems.map((item) {
      if (item is Map<String, dynamic>) {
        return CartItemModel.fromJson(item);
      }
      return CartItemModel(
        id: '',
        productoId: '',
        nombre: 'Producto',
        precio: 0,
        cantidad: 1,
      );
    }).toList();

    final orderId = json['id']?.toString() ?? json['pedidoId']?.toString() ?? '';
    final tot = (json['total'] is num) ? (json['total'] as num).toDouble() : 0.0;
    final sub = (json['subtotal'] is num) ? (json['subtotal'] as num).toDouble() : (tot > 5000 ? tot - 5000 : tot);
    final envio = (json['costoEnvio'] is num) ? (json['costoEnvio'] as num).toDouble() : 5000.0;

    final estadoNom = json['estadoNombre']?.toString() ??
        json['estadoPedidoNombre']?.toString() ??
        json['estadoPedido']?.toString() ??
        OrderStatusConstants.recibido;

    final estadoPagoNom = json['estadoPagoNombre']?.toString() ??
        json['estadoPago']?.toString() ??
        PaymentStatusConstants.iniciado;

    final metodoNom = json['metodoPagoNombre']?.toString() ??
        json['metodoPago']?.toString() ??
        PaymentMethodConstants.wompi;

    final dir = json['direccionEntrega']?.toString() ??
        json['direccion']?.toString();

    final zona = json['zona']?.toString() ??
        json['barrio']?.toString() ??
        'Bocagrande, Cartagena';

    final carpaNum = (json['carpa'] is num)
        ? (json['carpa'] as num).toInt()
        : ((json['mesa'] is num) ? (json['mesa'] as num).toInt() : null);

    return OrderModel(
      id: orderId,
      fecha: _formatFecha(json['fecha']?.toString()),
      total: tot,
      subtotal: sub,
      costoEnvio: envio,
      estadoPedido: estadoNom,
      estadoPago: estadoPagoNom,
      metodoPago: metodoNom,
      direccion: dir,
      barrio: zona,
      carpa: carpaNum,
      telefono: json['telefono']?.toString(),
      clienteNombre: json['clienteNombre']?.toString(),
      clienteEmail: json['clienteCorreo']?.toString() ?? json['clienteEmail']?.toString(),
      items: parsedItems,
    );
  }

  static String _formatFecha(String? raw) {
    if (raw == null || raw.isEmpty) return 'Reciente';
    try {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        final local = dt.toLocal();
        return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return raw;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha,
      'total': total,
      'subtotal': subtotal,
      'costoEnvio': costoEnvio,
      'estadoPedido': estadoPedido,
      'estadoPago': estadoPago,
      'metodoPago': metodoPago,
      'direccion': direccion,
      'barrio': barrio,
      'carpa': carpa,
      'telefono': telefono,
      'clienteNombre': clienteNombre,
      'clienteEmail': clienteEmail,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  Color get estadoPedidoColor {
    final lower = estadoPedido.toLowerCase();
    if (lower.contains('recibido')) return AppColors.primary;
    if (lower.contains('preparaci')) return AppColors.warning;
    if (lower.contains('terminado') || lower.contains('entregado')) return AppColors.success;
    if (lower.contains('cancelado')) return AppColors.danger;
    return AppColors.textMuted;
  }

  Color get estadoPagoColor {
    final lower = estadoPago.toLowerCase();
    if (lower.contains('pagado') || lower.contains('aprobado')) return AppColors.success;
    if (lower.contains('iniciado')) return AppColors.primary;
    if (lower.contains('pendiente')) return AppColors.warning;
    if (lower.contains('rechazado')) return AppColors.danger;
    return AppColors.textMuted;
  }

  String get metodoPagoLabel {
    final upper = metodoPago.toUpperCase();
    if (upper.contains('WOMPI')) return 'Wompi (Bancolombia)';
    if (upper.contains('EFECTIVO')) return 'Efectivo contraentrega';
    if (upper.contains('TRANSFERENCIA')) return 'Transferencia contraentrega';
    return metodoPago;
  }
}
