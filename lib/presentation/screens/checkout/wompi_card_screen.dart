import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/order_provider.dart';
import '../../widgets/custom_app_bar.dart';

class WompiCardScreen extends StatefulWidget {
  final Map<String, dynamic> checkoutData;

  const WompiCardScreen({super.key, required this.checkoutData});

  @override
  State<WompiCardScreen> createState() => _WompiCardScreenState();
}

class _WompiCardScreenState extends State<WompiCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberCtrl = TextEditingController(text: '4242424242424242');
  final _expCtrl = TextEditingController(text: '12/28');
  final _cvcCtrl = TextEditingController(text: '123');
  final _nameCtrl = TextEditingController(text: 'Turista Cartagena');
  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expCtrl.dispose();
    _cvcCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _useApprovedCard() {
    setState(() {
      _cardNumberCtrl.text = '4242424242424242';
      _expCtrl.text = '12/28';
      _cvcCtrl.text = '123';
      _nameCtrl.text = 'Turista Aprobado';
    });
  }

  void _useRejectedCard() {
    setState(() {
      _cardNumberCtrl.text = '4111111111111111';
      _expCtrl.text = '06/27';
      _cvcCtrl.text = '999';
      _nameCtrl.text = 'Turista Rechazado';
    });
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final total = widget.checkoutData['total'] as double;
    final shipmentData = widget.checkoutData['shipmentData'] as Map<String, dynamic>;
    final items = widget.checkoutData['items'] as List<CartItemModel>;
    final correo = widget.checkoutData['correo'] as String?;

    final cardNum = _cardNumberCtrl.text.replaceAll(' ', '').trim();
    final isApprovedCard = cardNum.startsWith('4242') || !cardNum.startsWith('4111');

    // Inicializar pago en backend
    final tempOrderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
    await orderProv.initWompiPayment(orderId: tempOrderId, amount: total);

    // Simular o verificar transacción con el backend
    await Future.delayed(const Duration(milliseconds: 1200));

    final verification = await orderProv.verifyWompiPayment(
      transactionId: 'TX_${DateTime.now().millisecondsSinceEpoch}',
      orderId: tempOrderId,
      status: isApprovedCard ? 'APPROVED' : 'DECLINED',
    );

    if (!mounted) return;

    if (verification.isApproved) {
      // Crear pedido pagado
      final order = await orderProv.createOrder(
        correo: correo ?? '',
        metodoPago: PaymentMethodConstants.wompi,
        direccion: shipmentData['direccion'] ?? 'Sector playa',
        barrio: shipmentData['barrio'] ?? 'Bocagrande',
        carpa: shipmentData['carpa'] as int?,
        telefono: shipmentData['telefono'] as String?,
        notas: shipmentData['notas'] as String?,
        total: total,
        items: items,
      );

      setState(() => _isProcessing = false);

      if (!mounted) return;

      if (order != null) {
        cart.clearCart();
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/order-confirmation',
          (route) => false,
          arguments: order,
        );
      }
    } else {
      setState(() => _isProcessing = false);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.error_outline, color: AppColors.danger),
              SizedBox(width: 8),
              Text('Transacción Rechazada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Text(
            verification.message.isNotEmpty
                ? verification.message
                : 'La tarjeta terminada en ${cardNum.substring(cardNum.length > 4 ? cardNum.length - 4 : 0)} fue declinada por Wompi Sandbox.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _useApprovedCard();
              },
              child: const Text('Usar Tarjeta Aprobada (4242)'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.checkoutData['total'] as double;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Wompi Sandbox Bancolombia'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Wompi Sandbox
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryDark.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.lock, color: AppColors.primaryDark, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pasarela Segura Wompi Sandbox (Bancolombia). Tus datos bancarios viajan encriptados.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.deepNavy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Chips de prueba rápida
              const Text(
                'Tarjetas de prueba Wompi Sandbox:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepNavy),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: const BorderSide(color: AppColors.success),
                        foregroundColor: AppColors.success,
                      ),
                      onPressed: _useApprovedCard,
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Aprobada (4242)', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: const BorderSide(color: AppColors.danger),
                        foregroundColor: AppColors.danger,
                      ),
                      onPressed: _useRejectedCard,
                      icon: const Icon(Icons.highlight_off, size: 16),
                      label: const Text('Rechazada (4111)', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Formulario de Tarjeta
              TextFormField(
                controller: _cardNumberCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de Tarjeta',
                  hintText: '4242 4242 4242 4242',
                  prefixIcon: Icon(Icons.credit_card, size: 20),
                ),
                validator: (v) => (v == null || v.trim().length < 13) ? 'Ingresa un número válido' : null,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Vence (MM/AA)',
                        hintText: '12/28',
                        prefixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      validator: (v) => (v == null || !v.contains('/')) ? 'MM/AA' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvcCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'CVC / CVV',
                        hintText: '123',
                        prefixIcon: Icon(Icons.security, size: 18),
                      ),
                      validator: (v) => (v == null || v.length < 3) ? 'CVC' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Titular',
                  hintText: 'Como aparece en la tarjeta',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre del titular' : null,
              ),
              const SizedBox(height: 28),

              // Total y Botón Pagar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total a Cobrar:', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                    Text(
                      CurrencyFormatter.formatCOP(total),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primaryDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Pagar ${CurrencyFormatter.formatCOP(total)}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
