import 'package:flutter/material.dart';
import '../data/seed_data.dart';
import '../models/pedido.dart';
import '../state/playapp_state.dart';
import '../theme/playapp_theme.dart';
import 'payment_gateway_screen.dart';

/// Selección de lugar de entrega en playa y método de pago (`shipment-payment.html`).
class ShipmentPaymentScreen extends StatefulWidget {
  const ShipmentPaymentScreen({super.key});

  @override
  State<ShipmentPaymentScreen> createState() => _ShipmentPaymentScreenState();
}

class _ShipmentPaymentScreenState extends State<ShipmentPaymentScreen> {
  ZonaPlaya _zonaSeleccionada = SeedData.zonasPlaya.first;
  final _mesaController = TextEditingController(text: '1');
  final _descripcionController = TextEditingController();
  String _metodoPago = 'Mercado Pago';

  static const _metodos = ['Mercado Pago', 'DEBITO', 'CREDITO', 'EFECTIVO'];

  @override
  void dispose() {
    _mesaController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _procederAlPago(PlayAppState state) {
    final mesa = int.tryParse(_mesaController.text.trim()) ?? 1;
    final envio = Envio(
      latitud: _zonaSeleccionada.latitud,
      longitud: _zonaSeleccionada.longitud,
      direccion: _zonaSeleccionada.direccion,
      mesaCarpa: mesa,
      descripcion: _descripcionController.text.trim().isEmpty
          ? 'Entrega en ${_zonaSeleccionada.nombre}, Carpa/Mesa $mesa'
          : _descripcionController.text.trim(),
    );

    final pedido = state.crearPedidoDesdeCarrito(
      envio: envio,
      metodoPago: _metodoPago,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PaymentGatewayScreen(pedido: pedido),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = PlayAppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Lugar de Entrega y Pago')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lugar de Entrega',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '¡Ya casi! Selecciona tu zona en la playa donde quieres recibir tu pedido.',
                    style: TextStyle(color: PlayAppColors.mutedText),
                  ),
                  const SizedBox(height: 12),
                  _BeachMapSelector(
                    selected: _zonaSeleccionada,
                    onSelected: (z) => setState(() => _zonaSeleccionada = z),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: SeedData.zonasPlaya.map((zona) {
                      final active = zona.id == _zonaSeleccionada.id;
                      return ChoiceChip(
                        label: Text(zona.nombre),
                        selected: active,
                        onSelected: (_) =>
                            setState(() => _zonaSeleccionada = zona),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información adicional',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: ValueKey(_zonaSeleccionada.direccion),
                    initialValue: _zonaSeleccionada.direccion,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Dirección detectada',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coordenadas: ${_zonaSeleccionada.latitud.toStringAsFixed(5)}, '
                    '${_zonaSeleccionada.longitud.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: PlayAppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _mesaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Carpa / Mesa',
                      prefixIcon: Icon(Icons.beach_access_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descripcionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción adicional',
                      hintText: 'Ej. Carpa azul frente al Kiosco El Bony',
                    ),
                  ),
                  const Divider(height: 28),
                  const Text(
                    'Pago',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _metodoPago,
                    decoration: const InputDecoration(
                      labelText: 'Método de pago',
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    items: _metodos
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _metodoPago = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total a pagar:',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        formatCop(state.totalCarrito),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: PlayAppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: state.carrito.isEmpty
                          ? null
                          : () => _procederAlPago(state),
                      icon: const Icon(Icons.payment),
                      label: const Text('Ir a pasarela'),
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

/// Mapa estilizado interactivo de la zona costera de Bocagrande / Cartagena.
class _BeachMapSelector extends StatelessWidget {
  const _BeachMapSelector({
    required this.selected,
    required this.onSelected,
  });

  final ZonaPlaya selected;
  final ValueChanged<ZonaPlaya> onSelected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 195,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, 195),
                  painter: _CartagenaCoastPainter(),
                ),
                ...SeedData.zonasPlaya.map((zona) {
                  final isSelected = zona.id == selected.id;
                  return Positioned(
                    left: (constraints.maxWidth * zona.rx) - 48,
                    top: (195 * zona.ry) - 22,
                    child: GestureDetector(
                      onTap: () => onSelected(zona),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_pin,
                            size: isSelected ? 34 : 26,
                            color: isSelected
                                ? PlayAppColors.dangerRed
                                : PlayAppColors.primaryBlue,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? PlayAppColors.darkHeader
                                  : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 3),
                              ],
                            ),
                            child: Text(
                              zona.nombre,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CartagenaCoastPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final seaPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), seaPaint);

    final sandPath = Path()
      ..moveTo(0, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.25,
        size.width,
        size.height * 0.35,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final sandPaint = Paint()..color = const Color(0xFFF3E2B8);
    canvas.drawPath(sandPath, sandPaint);

    final cityPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.42,
        size.width,
        size.height * 0.50,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(cityPath, Paint()..color = const Color(0xFFE5E7EB));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
