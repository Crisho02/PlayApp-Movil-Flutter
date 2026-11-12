import 'package:flutter/material.dart';
import '../models/pedido.dart';
import '../state/playapp_state.dart';
import '../theme/playapp_theme.dart';
import 'order_confirmation_screen.dart';

/// Pasarela de pago móvil oficial de PlayApp, fiel a `fake-payment-gateway.html`
/// y con soporte para el flujo de Mercado Pago (`PaymentController.java`).
class PaymentGatewayScreen extends StatefulWidget {
  const PaymentGatewayScreen({super.key, required this.pedido});

  final Pedido pedido;

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  bool _isProcessing = false;
  String? _processingStep;

  Future<void> _procesar({required bool aprobado, bool esMercadoPago = false}) async {
    setState(() {
      _isProcessing = true;
      _processingStep = esMercadoPago
          ? 'Conectando con pasarela Mercado Pago...'
          : 'Validando transacción bancaria...';
    });

    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;
    final state = PlayAppScope.of(context);
    final actualizado = state.finalizarPago(widget.pedido.id, aprobado: aprobado);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OrderConfirmationScreen(
          pedido: actualizado ?? widget.pedido,
          aprobado: aprobado,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: PlayAppColors.infoCyan,
        foregroundColor: PlayAppColors.darkHeader,
        title: Row(
          children: [
            Image.asset(
              'assets/images/Logo.png',
              height: 24,
              errorBuilder: (_, _, _) => const Icon(Icons.beach_access),
            ),
            const SizedBox(width: 8),
            const Text(
              'PLAYAPP · Pasarela de Pagos',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: PlayAppColors.successGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: PlayAppColors.successGreen.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 16, color: PlayAppColors.successGreen),
                          SizedBox(width: 6),
                          Text(
                            'Transacción Segura SSL 256-Bit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: PlayAppColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Realizar Pago',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Confirmación de pago para entrega en playa',
                      style: TextStyle(color: PlayAppColors.mutedText, fontSize: 13),
                    ),
                    const Divider(height: 28),

                    // Resumen de la Orden
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Número de orden:',
                                style: TextStyle(color: PlayAppColors.mutedText, fontSize: 13),
                              ),
                              Text(
                                '#${pedido.id}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Método de Pago:',
                                style: TextStyle(color: PlayAppColors.mutedText, fontSize: 13),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: PlayAppColors.primaryBlue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  pedido.pago.metodo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: PlayAppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Lugar de entrega:',
                                style: TextStyle(color: PlayAppColors.mutedText, fontSize: 13),
                              ),
                              Text(
                                'Carpa / Mesa ${pedido.envio.mesaCarpa}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Valor de la compra:',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                formatCop(pedido.total),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: PlayAppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_isProcessing) ...[
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(
                              _processingStep ?? 'Procesando pago...',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Botón Mercado Pago
                      if (pedido.pago.metodo.toLowerCase().contains('mercado') ||
                          pedido.pago.metodo == 'Mercado Pago') ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _procesar(aprobado: true, esMercadoPago: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF009EE3),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.payment, color: Colors.white),
                            label: const Text(
                              'Pagar con Mercado Pago',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Botón Efectuar Pago estándar (Aprobación)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _procesar(aprobado: false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: PlayAppColors.dangerRed,
                                side: const BorderSide(color: PlayAppColors.dangerRed),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Cancelar Pago'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _procesar(aprobado: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PlayAppColors.successGreen,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Efectuar Pago'),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 14),
                    const Text(
                      'Al efectuar el pago, tu orden pasa a "En preparación" y se descontará del inventario en playa.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: PlayAppColors.mutedText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
