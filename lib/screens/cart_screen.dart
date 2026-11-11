import 'package:flutter/material.dart';
import '../state/playapp_state.dart';
import '../theme/playapp_theme.dart';
import 'shipment_payment_screen.dart';

/// Pantalla de verificación de carrito (`checkout.html`).
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = PlayAppScope.of(context);
    final items = state.carrito;

    return Scaffold(
      appBar: AppBar(title: const Text('Verificación · Carrito')),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: PlayAppColors.mutedText,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tu carrito de compras está vacío',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Explora la tienda y agrega platos, bebidas o servicios de playa.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: PlayAppColors.mutedText),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        state.selectTab(1);
                      },
                      child: const Text('Ir a la Tienda'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Carrito de Compras',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: PlayAppColors.primaryBlue,
                          ),
                        ),
                        const Divider(height: 22),
                        ...items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: PlayAppColors.dangerRed,
                                  ),
                                  onPressed: () =>
                                      state.eliminarDelCarrito(item.producto.id),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    item.producto.imagenAsset,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.producto.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${formatCop(item.producto.precio)} x ${item.cantidad}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: PlayAppColors.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      onPressed: () => state.actualizarCantidadCarrito(
                                        item.producto.id,
                                        item.cantidad - 1,
                                      ),
                                    ),
                                    Text('${item.cantidad}'),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20),
                                      onPressed: () => state.actualizarCantidadCarrito(
                                        item.producto.id,
                                        item.cantidad + 1,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  formatCop(item.subtotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              formatCop(state.totalCarrito),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: PlayAppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ShipmentPaymentScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Comprar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
