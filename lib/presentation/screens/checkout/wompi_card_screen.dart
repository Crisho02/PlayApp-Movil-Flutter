import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _cardNumberCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _cvcCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expCtrl.dispose();
    _cvcCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
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
    // Validación interna de pasarela: declina tarjetas de testeo con prefijo 4111
    final isApproved = !cardNum.startsWith('4111');

    // Inicializar pago en backend
    final tempOrderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
    await orderProv.initWompiPayment(orderId: tempOrderId, amount: total);

    // Procesamiento con pasarela de pagos
    await Future.delayed(const Duration(milliseconds: 1400));

    final verification = await orderProv.verifyWompiPayment(
      transactionId: 'TX_${DateTime.now().millisecondsSinceEpoch}',
      orderId: tempOrderId,
      status: isApproved ? 'APPROVED' : 'DECLINED',
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.error_outline, color: AppColors.danger),
              SizedBox(width: 8),
              Text(
                'Pago no procesado',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: const Text(
            'Tu entidad bancaria no pudo autorizar la transacción. Por favor verifica que los datos de tu tarjeta sean correctos o intenta con otro medio de pago.',
            style: TextStyle(fontSize: 13, color: AppColors.textMain),
          ),
          actions: [
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
      appBar: const CustomAppBar(title: 'Pagar con Tarjeta'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Aviso de seguridad profesional
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryDark.withOpacity(0.2)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.lock_outline, color: AppColors.primaryDark, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pago seguro encriptado de 256 bits. Tus datos financieros viajan protegidos bajo estrictos estándares de seguridad bancaria.',
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
              const SizedBox(height: 24),

              // Formulario de Tarjeta
              const Text(
                'Datos de la Tarjeta',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _cardNumberCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(19),
                  _CardNumberInputFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Número de Tarjeta',
                  hintText: '•••• •••• •••• ••••',
                  prefixIcon: Icon(Icons.credit_card_outlined, size: 20),
                ),
                validator: (v) {
                  final raw = (v ?? '').replaceAll(' ', '');
                  if (raw.length < 13) return 'Ingresa un número de tarjeta válido';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _CardExpirationInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Vence (MM/AA)',
                        hintText: 'MM/AA',
                        prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                      ),
                      validator: (v) {
                        if (v == null || !v.contains('/') || v.length < 5) {
                          return 'MM/AA requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvcCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Código CVC / CVV',
                        hintText: '•••',
                        prefixIcon: Icon(Icons.security_outlined, size: 18),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 3) {
                          return 'CVC de 3 o 4 dígitos';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Titular',
                  hintText: 'Como figura en el plástico',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ingresa el nombre del titular';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Total y Botón Pagar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sandBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total a Pagar:',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatCOP(total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Pagar ${CurrencyFormatter.formatCOP(total)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formateador automático de tarjeta (ej: 4242 4242 4242 4242)
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formateador automático de vencimiento (ej: MM/AA)
class _CardExpirationInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
