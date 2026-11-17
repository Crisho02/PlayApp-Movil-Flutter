import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/order_model.dart';
import '../../../providers/order_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/order_detail_modal.dart';
import '../../widgets/status_badge.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  String _filter = 'TODOS'; // 'TODOS', 'ACTIVOS', 'TERMINADOS'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchUserOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = Provider.of<OrderProvider>(context);

    List<OrderModel> filteredOrders = orderProv.userOrders;
    if (_filter == 'ACTIVOS') {
      filteredOrders = filteredOrders
          .where((o) =>
              o.estadoPedido == OrderStatusConstants.recibido ||
              o.estadoPedido == OrderStatusConstants.enPreparacion)
          .toList();
    } else if (_filter == 'TERMINADOS') {
      filteredOrders = filteredOrders
          .where((o) => o.estadoPedido == OrderStatusConstants.terminado)
          .toList();
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Mis Pedidos de Playa'),
      body: Column(
        children: [
          // Filtros
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('Todos', 'TODOS'),
                const SizedBox(width: 8),
                _buildFilterChip('En Curso', 'ACTIVOS'),
                const SizedBox(width: 8),
                _buildFilterChip('Terminados', 'TERMINADOS'),
              ],
            ),
          ),

          // Lista de pedidos
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => orderProv.fetchUserOrders(),
              color: AppColors.primary,
              child: Builder(
                builder: (context) {
                  if (orderProv.isLoading && orderProv.userOrders.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (filteredOrders.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textLight),
                              SizedBox(height: 12),
                              Text(
                                'No tienes pedidos en esta sección',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Tus pedidos de playa aparecerán aquí.',
                                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildOrderCard(context, order);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : AppColors.sandBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : AppColors.sandBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMain,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => OrderDetailModal.show(context, order),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila Superior: Código y Fecha
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          order.displayCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.deepNavy,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      order.fecha,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
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
                      isSmall: true,
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: order.estadoPago,
                      color: order.estadoPagoColor,
                      isSmall: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Fila Inferior: Total y Detalles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total (${order.items.isNotEmpty ? "${order.items.length} items" : "1 pedido"})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        Text(
                          CurrencyFormatter.formatCOP(order.total),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: const [
                        Text(
                          'Ver detalle modal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
