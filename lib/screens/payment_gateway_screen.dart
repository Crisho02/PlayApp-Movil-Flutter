import 'package:flutter/material.dart';
import '../models/pedido.dart';
import '../state/playapp_state.dart';
import '../theme/playapp_theme.dart';
import 'order_confirmation_screen.dart';

/// Pasarela de pago simulada fiel a `fake-payment-gateway.html`.
class PaymentGatewayScreen extends StatelessWidget {
  const PaymentGatewayScreen({super.key, required this.pedido});

  final Pedido pedido;

  void _procesar(BuildContext context, {required bool aprobado}) {
    final state = PlayAppScope.of(context);
    final actualizado = state.finalizarPago(pedido.id, aprobado: aprobado);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OrderConfirmationScreen(
          pedido: actualizado ?? pedido,
          aprobado: aprobado,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: PlayAppColors.infoCyan,
        foregroundColor: PlayAppColors.darkHeader,
        title: const Text(
          'PLAYAPP · Pasarela de Pago',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 46,
                    color: PlayAppColors.primaryBlue,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Realizar Pago',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Orden #${pedido.id}',
                    style: const TextStyle(color: PlayAppColors.mutedText),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Valor de la compra: ${formatCop(pedido.total)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Método de Pago: ${pedido.pago.metodo}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _procesar(context, aprobado: false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PlayAppColors.dangerRed,
                            side: const BorderSide(color: PlayAppColors.dangerRed),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancelar Pago'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _procesar(context, aprobado: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PlayAppColors.successGreen,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Efectuar Pago'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
