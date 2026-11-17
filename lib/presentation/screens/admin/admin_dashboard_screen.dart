import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/order_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/order_detail_modal.dart';
import '../../widgets/status_badge.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchAdminData();
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showChangeStatusDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Actualizar Estado: ${order.displayCode}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.inbox, color: AppColors.primary),
              title: const Text(OrderStatusConstants.recibido),
              onTap: () {
                Navigator.pop(ctx);
                _updateStatus(order.id, OrderStatusConstants.recibido);
              },
            ),
            ListTile(
              leading: const Icon(Icons.outdoor_grill, color: AppColors.warning),
              title: const Text(OrderStatusConstants.enPreparacion),
              onTap: () {
                Navigator.pop(ctx);
                _updateStatus(order.id, OrderStatusConstants.enPreparacion);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppColors.success),
              title: const Text(OrderStatusConstants.terminado),
              onTap: () {
                Navigator.pop(ctx);
                _updateStatus(order.id, OrderStatusConstants.terminado);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppColors.danger),
              title: const Text(OrderStatusConstants.cancelado),
              onTap: () {
                Navigator.pop(ctx);
                _updateStatus(order.id, OrderStatusConstants.cancelado);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final ok = await admin.updateOrderStatus(orderId, newStatus);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a "$newStatus"'),
          backgroundColor: AppColors.primaryDark,
        ),
      );
    }
  }

  void _showCreateProductDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    int categoryId = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo Producto Playero'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Precio (COP)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock Disponible'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: categoryId,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Comidas')),
                    DropdownMenuItem(value: 2, child: Text('Bebidas')),
                    DropdownMenuItem(value: 3, child: Text('Servicios')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => categoryId = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final admin = Provider.of<AdminProvider>(context, listen: false);
                final prod = Provider.of<ProductProvider>(context, listen: false);
                await admin.createProduct(
                  nombre: nameCtrl.text,
                  descripcion: descCtrl.text,
                  precio: double.tryParse(priceCtrl.text) ?? 10000.0,
                  cantidad: int.tryParse(stockCtrl.text) ?? 10,
                  categoriaId: categoryId,
                );
                await prod.fetchProducts();
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    // Validación estricta de rol
    if (user == null || !user.isAdmin) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Acceso Denegado', showCart: false),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, size: 72, color: AppColors.danger),
                const SizedBox(height: 16),
                const Text(
                  'Acceso Restringido para Administradores',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta sección solo está disponible para usuarios con rol ROLE_ADMIN de PlayApp.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final adminProv = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              adminProv.fetchAdminData();
              Provider.of<ProductProvider>(context, listen: false).fetchProducts();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryDark,
          tabs: const [
            Tab(icon: Icon(Icons.insights, size: 20), text: 'Métricas'),
            Tab(icon: Icon(Icons.receipt_long, size: 20), text: 'Pedidos'),
            Tab(icon: Icon(Icons.fastfood, size: 20), text: 'Productos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Métricas & Clima
          _buildMetricsTab(adminProv),

          // Tab 2: Pedidos
          _buildOrdersTab(adminProv),

          // Tab 3: Productos
          _buildProductsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton.extended(
              onPressed: _showCreateProductDialog,
              backgroundColor: AppColors.primaryDark,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Plato'),
            )
          : null,
    );
  }

  Widget _buildMetricsTab(AdminProvider admin) {
    final m = admin.metrics;
    final ventas = m['totalVentas'] ?? 845000.0;
    final totalPedidos = m['pedidosTotales'] ?? 34;
    final pendientes = m['pedidosPendientes'] ?? 6;
    final terminados = m['pedidosTerminados'] ?? 28;
    final ocupBocagrande = m['ocupacionBocagrande'] ?? 78;
    final ocupCastillo = m['ocupacionCastillo'] ?? 62;
    final temp = m['temperatura'] ?? 31;
    final clima = m['clima'] ?? 'Soleado con brisa de playa';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Clima Cartagena
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.deepNavy, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny_rounded, color: AppColors.warning, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Condiciones en Playas de Cartagena',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$temp°C • $clima',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KPIs
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Ventas',
                  value: CurrencyFormatter.formatCOP(ventas),
                  icon: Icons.payments,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Pedidos Totales',
                  value: '$totalPedidos',
                  icon: Icons.receipt_long,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Por Preparar',
                  value: '$pendientes',
                  icon: Icons.outdoor_grill,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Entregados',
                  value: '$terminados',
                  icon: Icons.check_circle,
                  color: AppColors.turquoise,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Ocupación de Playas
          const Text(
            'Estimación de Ocupación por Sector',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sandBorder),
            ),
            child: Column(
              children: [
                _buildOccupancyBar('Bocagrande (Kiosco El Bony)', ocupBocagrande, AppColors.coral),
                const SizedBox(height: 14),
                _buildOccupancyBar('Castillogrande (Bahía)', ocupCastillo, AppColors.turquoise),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.deepNavy),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyBar(String beach, int percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(beach, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            Text('$percent%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100.0,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab(AdminProvider admin) {
    final orders = admin.adminOrders;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.displayCode,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.deepNavy),
                  ),
                  Text(order.fecha, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Cliente: ${order.clienteNombre ?? "Turista"} • ${order.barrio ?? "Playa"} • Carpa: #${order.carpa ?? 1}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMain),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  StatusBadge(label: order.estadoPedido, color: order.estadoPedidoColor, isSmall: true),
                  const SizedBox(width: 8),
                  StatusBadge(label: order.estadoPago, color: order.estadoPagoColor, isSmall: true),
                  const Spacer(),
                  Text(
                    CurrencyFormatter.formatCOP(order.total),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primaryDark),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Botones de acción del admin
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => OrderDetailModal.show(context, order),
                    child: const Text('Ver Modal', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  if (order.estadoPago != PaymentStatusConstants.pagado) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                      ),
                      onPressed: () => admin.markOrderAsPaid(order.id),
                      child: const Text('Marcar Pagado', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => _showChangeStatusDialog(order),
                    child: const Text('Cambiar Estado', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductsTab() {
    final prodProv = Provider.of<ProductProvider>(context);
    final admin = Provider.of<AdminProvider>(context);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: prodProv.allProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = prodProv.allProducts[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 50,
                  height: 50,
                  color: AppColors.sandBackground,
                  child: Image.asset(
                    p.localAssetFallback ?? AppAssets.placeholder,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      '${CurrencyFormatter.formatCOP(p.precio)} • Stock: ${p.cantidadDisponible}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                onPressed: () async {
                  await admin.deleteProduct(p.id);
                  await prodProv.fetchProducts();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
