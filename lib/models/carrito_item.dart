import 'producto.dart';

/// Ítem agregado al carrito de compras de un cliente.
class CarritoItem {
  const CarritoItem({
    required this.producto,
    required this.cantidad,
  });

  final Producto producto;
  final int cantidad;

  double get subtotal => producto.precio * cantidad;

  CarritoItem copyWith({Producto? producto, int? cantidad}) {
    return CarritoItem(
      producto: producto ?? this.producto,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}
