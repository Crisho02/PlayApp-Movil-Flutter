import 'package:flutter/material.dart';
import '../theme/playapp_theme.dart';

/// Categorías del catálogo costero de PlayApp (1: Comida, 2: Bebida, 3: Servicio).
enum CategoriaProducto {
  comida(1, 'Comida', PlayAppColors.primaryBlue),
  bebida(2, 'Bebida', PlayAppColors.warningAmber),
  servicio(3, 'Servicio', PlayAppColors.successGreen);

  const CategoriaProducto(this.codigo, this.etiqueta, this.badgeColor);

  final int codigo;
  final String etiqueta;
  final Color badgeColor;

  Color get textColor =>
      this == CategoriaProducto.bebida ? const Color(0xFF1F2937) : Colors.white;

  static CategoriaProducto fromCodigo(int? codigo) {
    return CategoriaProducto.values.firstWhere(
      (c) => c.codigo == codigo,
      orElse: () => CategoriaProducto.comida,
    );
  }
}

/// Representa un producto o servicio disponible en la tienda PlayApp.
class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.categoria,
    required this.imagenAsset,
    required this.entidadNombre,
    this.tipo = 1,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final CategoriaProducto categoria;
  final String imagenAsset;
  final String entidadNombre;
  final int tipo;

  Producto copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    double? precio,
    int? stock,
    CategoriaProducto? categoria,
    String? imagenAsset,
    String? entidadNombre,
    int? tipo,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      categoria: categoria ?? this.categoria,
      imagenAsset: imagenAsset ?? this.imagenAsset,
      entidadNombre: entidadNombre ?? this.entidadNombre,
      tipo: tipo ?? this.tipo,
    );
  }
}
