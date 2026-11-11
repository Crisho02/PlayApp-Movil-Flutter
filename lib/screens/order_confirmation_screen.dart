import 'package:flutter/material.dart';
import '../models/pedido.dart';
import '../state/playapp_state.dart';
import '../theme/playapp_theme.dart';

/// Confirmación del pedido (`pedido-confirmacion.html`).
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.pedido,
    required this.aprobado,
  });

  final Pedido pedido;
  final bool aprobado;

  @override
  Widget build(BuildContext context) {
    final state = PlayAppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación de Pedido')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: aprobado
                  ? PlayAppColors.successGreen.withValues(alpha: 0.14)
                  : PlayAppColors.dangerRed.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: aprobado
                    ? PlayAppColors.successGreen
                    : PlayAppColors.dangerRed,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  aprobado ? Icons.check_circle : Icons.error_outline,
                  color: aprobado
                      ? PlayAppColors.successGreen
                      : PlayAppColors.dangerRed,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    aprobado
                        ? '¡Compra realizada con éxito!'
                        : 'El pago fue cancelado. Puedes reintentar desde la sección de Pedidos.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Pedido #${pedido.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Entrega: ${pedido.envio.direccion} · Carpa/Mesa ${pedido.envio.mesaCarpa}',
                    style: const TextStyle(
                      color: PlayAppColors.mutedText,
                      fontSize: 13,
                    ),
                  ),
                  const Divider(height: 22),
                  const Text(
                    'Items',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...pedido.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('${item.nombre} x ${item.cantidad}'),
                          ),
                          Text(
                            formatCop(item.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        formatCop(pedido.total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: PlayAppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).popUntil((r) => r.isFirst);
                            state.selectTab(2);
                          },
                          child: const Text('Ver mis pedidos'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).popUntil((r) => r.isFirst);
                            state.selectTab(1);
                          },
                          child: const Text('Seguir comprando'),
                        ),
                      ),
                    ],
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
