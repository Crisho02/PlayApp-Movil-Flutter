import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import 'cart_item_model.dart';

class OrderModel {
  final String id;
  final String fecha;
  final double total;
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
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems.map((item) {
      if (item is Map<String, dynamic>) {
        return CartItemModel.fromJson(item);
      }
      return CartItemModel(
        id: '',
        productoId: '',
        nombre: 'Item',
        precio: 0,
        cantidad: 1,
      );
    }).toList();

    return OrderModel(
      id: json['id']?.toString() ?? json['pedidoId']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      total: (json['total'] is num) ? (json['total'] as num).toDouble() : 0.0,
      estadoPedido: json['estadoPedido']?.toString() ?? OrderStatusConstants.recibido,
      estadoPago: json['estadoPago']?.toString() ?? PaymentStatusConstants.iniciado,
      metodoPago: json['metodoPago']?.toString() ?? PaymentMethodConstants.wompi,
      direccion: json['direccion']?.toString(),
      barrio: json['barrio']?.toString(),
      carpa: (json['carpa'] is num)
          ? (json['carpa'] as num).toInt()
          : ((json['mesa'] is num) ? (json['mesa'] as num).toInt() : null),
      telefono: json['telefono']?.toString(),
      clienteNombre: json['clienteNombre']?.toString(),
      clienteEmail: json['clienteEmail']?.toString(),
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha,
      'total': total,
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
    switch (estadoPedido) {
      case OrderStatusConstants.recibido:
        return AppColors.primary;
      case OrderStatusConstants.enPreparacion:
        return AppColors.warning;
      case OrderStatusConstants.terminado:
        return AppColors.success;
      case OrderStatusConstants.cancelado:
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  Color get estadoPagoColor {
    switch (estadoPago) {
      case PaymentStatusConstants.pagado:
      case PaymentStatusConstants.aprobado:
        return AppColors.success;
      case PaymentStatusConstants.iniciado:
        return AppColors.primary;
      case PaymentStatusConstants.pendienteContraentrega:
        return AppColors.warning;
      case PaymentStatusConstants.rechazado:
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  String get metodoPagoLabel {
    switch (metodoPago) {
      case PaymentMethodConstants.wompi:
        return 'Wompi (Bancolombia)';
      case PaymentMethodConstants.efectivo:
        return 'Efectivo contraentrega';
      case PaymentMethodConstants.transferencia:
        return 'Transferencia contraentrega';
      default:
        return metodoPago;
    }
  }
}
