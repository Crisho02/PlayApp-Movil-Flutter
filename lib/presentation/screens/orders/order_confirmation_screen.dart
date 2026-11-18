import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/order_model.dart';
import '../../widgets/status_badge.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final OrderModel order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isWompi = order.metodoPago == PaymentMethodConstants.wompi;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.success.withOpacity(0.3), width: 3),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 72,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '¡Pedido Confirmado!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.displayCode,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StatusBadge(label: order.estadoPedido, color: order.estadoPedidoColor),
                        const SizedBox(width: 8),
                        StatusBadge(label: order.estadoPago, color: order.estadoPagoColor),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Explicación
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.sandBorder),
                      ),
                      child: Text(
                        isWompi
                            ? 'Tu pago ha sido aprobado exitosamente a través de Wompi (Bancolombia). Ya iniciamos la preparación de tus productos para entregarlos directamente en tu carpa de playa.'
                            : 'Tu pedido contraentrega ha sido recibido con éxito. Ten preparado el monto en ${order.metodoPagoLabel.toLowerCase()} al recibir tus productos en la carpa.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMain,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Resumen de Entrega
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.sandBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Playa:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                              Text(order.barrio ?? 'Bocagrande', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                          if (order.carpa != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Carpa / Mesa:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                Text('#${order.carpa}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryDark)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Método de Pago:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                              Text(order.metodoPagoLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pagado / a Pagar:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              Text(
                                CurrencyFormatter.formatCOP(order.total),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primaryDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botones de acción
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
                        },
                        icon: const Icon(Icons.home, size: 18),
                        label: const Text('Volver al Inicio'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(context, '/orders', (route) => false);
                        },
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: const Text('Ver Mis Pedidos'),
                      ),
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
