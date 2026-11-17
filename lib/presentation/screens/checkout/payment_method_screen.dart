import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/order_provider.dart';
import '../../widgets/custom_app_bar.dart';

class PaymentMethodScreen extends StatefulWidget {
  final Map<String, dynamic> shipmentData;

  const PaymentMethodScreen({super.key, required this.shipmentData});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String _selectedMethod = PaymentMethodConstants.wompi;
  bool _isSubmitting = false;

  Future<void> _handleConfirm() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    if (user == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Inicio de Sesión Requerido'),
          content: const Text('Para confirmar tu pedido en la playa, por favor inicia sesión con tu cuenta de PlayApp.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Iniciar Sesión'),
            ),
          ],
        ),
      );
      return;
    }

    final cart = Provider.of<CartProvider>(context, listen: false);
    final orderProv = Provider.of<OrderProvider>(context, listen: false);

    if (_selectedMethod == PaymentMethodConstants.wompi) {
      // Flujo de Wompi Sandbox
      Navigator.pushNamed(
        context,
        '/checkout-wompi-card',
        arguments: {
          'shipmentData': widget.shipmentData,
          'total': cart.total,
          'items': cart.itemsList,
          'correo': user.email,
        },
      );
    } else {
      // Flujo Contraentrega (Efectivo o Transferencia)
      setState(() => _isSubmitting = true);

      final order = await orderProv.createOrder(
        correo: user.email,
        metodoPago: _selectedMethod,
        direccion: widget.shipmentData['direccion'] ?? 'Sector playa',
        barrio: widget.shipmentData['barrio'] ?? 'Bocagrande',
        carpa: widget.shipmentData['carpa'] as int?,
        telefono: widget.shipmentData['telefono'] as String?,
        notas: widget.shipmentData['notas'] as String?,
        total: cart.total,
        items: cart.itemsList,
      );

      setState(() => _isSubmitting = false);

      if (!mounted) return;

      if (order != null) {
        cart.clearCart();
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/order-confirmation',
          (route) => false,
          arguments: order,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProv.errorMessage ?? 'Error al procesar el pedido'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Método de Pago'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stepper
            Row(
              children: [
                _buildStepBubble('1', 'Entrega', true),
                Expanded(child: Container(height: 2, color: AppColors.primary)),
                _buildStepBubble('2', 'Pago', true),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Método de Pago',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Selecciona cómo deseas pagar tu pedido de playa:',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),

            // Opción 1: Wompi (Bancolombia) [Recomendado]
            _buildPaymentCard(
              id: PaymentMethodConstants.wompi,
              title: 'Wompi (Bancolombia)',
              badge: 'Recomendado',
              badgeColor: AppColors.primaryDark,
              description: 'Tarjetas Débito/Crédito, Nequi, PSE y Botón Bancolombia.',
              icon: Icons.credit_card_outlined,
            ),
            const SizedBox(height: 14),

            // Opción 2: Efectivo contraentrega
            _buildPaymentCard(
              id: PaymentMethodConstants.efectivo,
              title: 'Efectivo contraentrega',
              description: 'Paga en efectivo cuando recibas tu pedido en la playa.',
              icon: Icons.payments_outlined,
            ),
            const SizedBox(height: 14),

            // Opción 3: Transferencia contraentrega
            _buildPaymentCard(
              id: PaymentMethodConstants.transferencia,
              title: 'Transferencia contraentrega',
              description: 'Realiza la transferencia al recibir tu pedido.',
              icon: Icons.account_balance_outlined,
            ),
            const SizedBox(height: 28),

            // Resumen de Orden
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
                      const Text('Total con envío incluido:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      Text(
                        CurrencyFormatter.formatCOP(cart.total),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botón de Confirmación
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleConfirm,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _selectedMethod == PaymentMethodConstants.wompi
                            ? 'Pagar con Wompi Sandbox'
                            : 'Confirmar Pedido Contraentrega',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard({
    required String id,
    required String title,
    String? badge,
    Color? badgeColor,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == id;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = id),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.turquoiseLight.withOpacity(0.3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.sandBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppColors.primaryDark : AppColors.textLight,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor ?? AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: isSelected ? AppColors.primaryDark : AppColors.textMuted, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBubble(String number, String label, bool active) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? AppColors.primaryDark : AppColors.textMuted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
