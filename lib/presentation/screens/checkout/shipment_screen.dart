import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../widgets/beach_map_widget.dart';
import '../../widgets/custom_app_bar.dart';

class ShipmentScreen extends StatefulWidget {
  const ShipmentScreen({super.key});

  @override
  State<ShipmentScreen> createState() => _ShipmentScreenState();
}

class _ShipmentScreenState extends State<ShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedZone = 'Bocagrande (Kiosco El Bony)';
  final _addressCtrl = TextEditingController(text: 'Cra. 1 frente a Kiosco El Bony, Bocagrande');
  final _carpaCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  double _latitud = 10.3997;
  double _longitud = -75.5562;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      if (user.telefono != null) _phoneCtrl.text = user.telefono!;
      if (user.mesa != null) _carpaCtrl.text = user.mesa.toString();
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _carpaCtrl.dispose();
    _notesCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pushNamed(
      context,
      '/checkout-payment',
      arguments: {
        'barrio': _selectedZone,
        'direccion': _addressCtrl.text.isNotEmpty
            ? _addressCtrl.text
            : 'Sector playa $_selectedZone',
        'carpa': int.tryParse(_carpaCtrl.text) ?? 1,
        'telefono': _phoneCtrl.text,
        'notas': _notesCtrl.text,
        'latitud': _latitud,
        'longitud': _longitud,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Ubicación de Entrega'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stepper visual
              Row(
                children: [
                  _buildStepBubble('1', 'Entrega', true),
                  Expanded(child: Container(height: 2, color: AppColors.primary)),
                  _buildStepBubble('2', 'Pago', false),
                ],
              ),
              const SizedBox(height: 20),

              // Widget de selección de playa y mapa interactivo de Bocagrande
              BeachMapWidget(
                selectedZone: _selectedZone,
                onZoneChanged: (zone) => setState(() => _selectedZone = zone),
                carpaController: _carpaCtrl,
                notesController: _notesCtrl,
                addressController: _addressCtrl,
                onLocationChanged: (lat, lng) {
                  _latitud = lat;
                  _longitud = lng;
                },
              ),
              const SizedBox(height: 16),

              // Punto de Entrega / Dirección en Playa
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Punto de Entrega / Dirección en Playa',
                  hintText: 'Ej: Frente a Hotel Caribe, sector carpas azules',
                  prefixIcon: Icon(Icons.place_outlined, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ingresa o marca en el mapa un punto de entrega válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Teléfono de contacto
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono de Contacto (WhatsApp)',
                  hintText: '300 123 4567 para avisarte cuando llegue el delivery',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa un número de contacto';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botón de continuar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: cart.isEmpty ? null : _nextStep,
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('Continuar a Método de Pago'),
                ),
              ),
            ],
          ),
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
