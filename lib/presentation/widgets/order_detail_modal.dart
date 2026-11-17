import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/image_helper.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_provider.dart';
import 'status_badge.dart';

class OrderDetailModal extends StatefulWidget {
  final OrderModel order;

  const OrderDetailModal({
    super.key,
    required this.order,
  });

  static void show(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderDetailModal(order: order),
    );
  }

  @override
  State<OrderDetailModal> createState() => _OrderDetailModalState();
}

class _OrderDetailModalState extends State<OrderDetailModal> {
  late OrderModel _currentOrder;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    if (_currentOrder.items.isEmpty) {
      _loadServerDetails();
    }
  }

  Future<void> _loadServerDetails() async {
    setState(() => _isLoadingDetails = true);
    final prov = Provider.of<OrderProvider>(context, listen: false);
    final detailed = await prov.fetchOrderDetail(_currentOrder.id);
    if (mounted && detailed != null) {
      setState(() {
        _currentOrder = detailed;
        _isLoadingDetails = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingDetails = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _currentOrder;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de arrastre
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalle del Pedido',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  Text(
                    order.displayCode,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Badges de Estado
          Row(
            children: [
              StatusBadge(
                label: order.estadoPedido,
                color: order.estadoPedidoColor,
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: order.estadoPago,
                color: order.estadoPagoColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Contenido scrollable
          Expanded(
            child: _isLoadingDetails
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Datos de Entrega
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.sandBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.sandBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.location_on_outlined, size: 18, color: AppColors.primaryDark),
                                  SizedBox(width: 6),
                                  Text(
                                    'Punto de Entrega en Playa',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.deepNavy,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sector: ${order.barrio ?? "Bocagrande, Cartagena"}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                              ),
                              if (order.direccion != null && order.direccion!.isNotEmpty)
                                Text(
                                  'Referencia: ${order.direccion}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                                ),
                              if (order.carpa != null)
                                Text(
                                  'Carpa / Mesa: #${order.carpa}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              if (order.telefono != null && order.telefono!.isNotEmpty)
                                Text(
                                  'Teléfono de contacto: ${order.telefono}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Lista de Productos
                        const Text(
                          'Productos Solicitados',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.deepNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (order.items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Menú playero seleccionado',
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                          )
                        else
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: SizedBox(
                                      width: 38,
                                      height: 38,
                                      child: ImageHelper.buildProductImage(
                                        imageSrc: item.imagenSrc,
                                        imageUrl: item.imagenUrl,
                                        productId: item.productoId,
                                        assetFallback: item.assetFallback,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.turquoiseLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.cantidad}x',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AppColors.turquoise,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.nombre,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMain,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatCOP(
                                      item.subtotal > 0
                                          ? item.subtotal
                                          : item.precio * item.cantidad,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.deepNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // Desglose
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Método de Pago:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            Text(
                              order.metodoPagoLabel,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Fecha de Pedido:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            Text(
                              order.fecha,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Tarifa Envío a Carpa:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            Text('\$ 5.000 COP', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.deepNavy,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatCOP(order.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }
}
