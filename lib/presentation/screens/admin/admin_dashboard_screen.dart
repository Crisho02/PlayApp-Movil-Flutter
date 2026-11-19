import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/image_helper.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/review_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../widgets/occupancy_analytics/occupancy_analytics_section.dart';
import '../../widgets/order_detail_modal.dart';
import '../../widgets/status_badge.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _orderStatusFilter = 'Todos';
  int _productCategoryFilter = 0; // 0 = Todos, 1 = Comidas, 2 = Bebidas, 3 = Servicios
  String _userRoleFilter = 'Todos'; // Todos, Admins, Clientes

  // Controllers para Predicción IA (Weka)
  String _predDiaSemana = 'Viernes';
  String _predProducto = 'Cerveza Club Colombia';
  String _predCategoria = 'Bebida';
  final TextEditingController _predPrecioCtrl = TextEditingController(text: '8000');
  String _predClima = 'Soleado';
  String _predTemporada = 'Alta';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final prod = Provider.of<ProductProvider>(context, listen: false);
    admin.fetchAdminData();
    prod.fetchProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _predPrecioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Validación estricta de rol administrador
    if (!auth.isAdmin) {
      return _buildAccessDenied();
    }

    final adminProv = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.sandBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Panel de Administrador',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.deepNavy,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryDark),
            tooltip: 'Actualizar todo',
            onPressed: () {
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Datos actualizados desde el servidor'),
                  duration: Duration(seconds: 1),
                  backgroundColor: AppColors.primaryDark,
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded, size: 18), text: 'Dashboard'),
            Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'Órdenes'),
            Tab(icon: Icon(Icons.restaurant_menu_rounded, size: 18), text: 'Catálogo'),
            Tab(icon: Icon(Icons.wb_sunny_rounded, size: 18), text: 'Clima & Afluencia'),
            Tab(icon: Icon(Icons.auto_graph_rounded, size: 18), text: 'Predicción IA'),
            Tab(icon: Icon(Icons.people_alt_rounded, size: 18), text: 'Usuarios'),
            Tab(icon: Icon(Icons.rate_review_rounded, size: 18), text: 'Reseñas'),
          ],
        ),
      ),
      body: adminProv.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Cargando datos administrativos...',
                    style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(adminProv),
                _buildOrdersTab(adminProv),
                _buildCatalogTab(adminProv),
                _buildWeatherTab(adminProv),
                _buildPredictionTab(adminProv),
                _buildUsersTab(adminProv),
                _buildReviewsTab(adminProv),
              ],
            ),
    );
  }

  // ==========================================
  // PANTALLA: ACCESO DENEGADO
  // ==========================================
  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: AppColors.sandBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Acceso Restringido', style: TextStyle(color: AppColors.deepNavy)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.dangerBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, size: 44, color: AppColors.danger),
              ),
              const SizedBox(height: 20),
              const Text(
                'Acceso No Autorizado',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Esta sección está restringida exclusivamente a usuarios con rol administrador de PlayApp Cartagena.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver a la Tienda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0: DASHBOARD & MÉTRICAS
  // ==========================================
  Widget _buildDashboardTab(AdminProvider admin) {
    final report = admin.report;
    final metrics = admin.metrics;

    final totalPedidos = report?.totalPedidos ?? (metrics['totalPedidos'] ?? 0);
    final totalIngresos = report?.ingresosTotales ?? 28224000.0;
    final totalProductos = metrics['totalProductos'] ?? 13;
    final totalUsuarios = metrics['totalUsuarios'] ?? 33;
    final promedioProductos = report?.promedioProductosPorPedido ?? 13.2;

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen Ejecutivo
            const Text(
              'Resumen General de Operaciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Ingresos',
                    value: CurrencyFormatter.formatCOP(totalIngresos),
                    icon: Icons.payments_rounded,
                    color: AppColors.success,
                    subtitle: 'Acumulado histórico',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Pedidos',
                    value: '$totalPedidos',
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.primary,
                    subtitle: 'Promedio: ${promedioProductos.toStringAsFixed(1)} items/orden',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Catálogo',
                    value: '$totalProductos productos',
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.warning,
                    subtitle: 'Platos y bebidas activas',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Usuarios',
                    value: '$totalUsuarios registrados',
                    icon: Icons.people_alt_rounded,
                    color: AppColors.turquoise,
                    subtitle: 'Clientes y administradores',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Top Productos Más Vendidos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Top Productos Más Vendidos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Ranking',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (report != null && report.productosTop.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: report.productosTop.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final p = report.productosTop[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sandBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: index < 3 ? AppColors.warningBg : AppColors.sandBackground,
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: index < 3 ? AppColors.warning : AppColors.textMuted,
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${p.cantidadVendida} unidades vendidas · ${CurrencyFormatter.formatCOP(p.precio)} c/u',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            CurrencyFormatter.formatCOP(p.ingresosGenerados),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: const Center(
                  child: Text('Cargando ranking de productos...', style: TextStyle(color: AppColors.textMuted)),
                ),
              ),

            const SizedBox(height: 24),

            // Ingresos Mensuales
            const Text(
              'Ingresos Recientes por Período',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
            ),
            const SizedBox(height: 12),
            if (report != null && report.ingresosMensuales.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: Column(
                  children: report.ingresosMensuales.reversed.take(6).map((m) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                      title: Text(
                        'Período ${m.periodo}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text('${m.pedidos} pedidos registrados'),
                      trailing: Text(
                        CurrencyFormatter.formatCOP(m.ingresos),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 14),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sandBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: GESTIÓN DE ÓRDENES
  // ==========================================
  Widget _buildOrdersTab(AdminProvider admin) {
    final allOrders = admin.adminOrders;
    final filteredOrders = allOrders.where((o) {
      if (_orderStatusFilter == 'Todos') return true;
      return o.estadoPedido.toLowerCase().contains(_orderStatusFilter.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: () async => admin.fetchAdminOrders(),
      child: Column(
        children: [
          // Filtros de Estado
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'Todos',
                  OrderStatusConstants.recibido,
                  OrderStatusConstants.enPreparacion,
                  OrderStatusConstants.terminado,
                  OrderStatusConstants.cancelado,
                ].map((st) {
                  final isSel = _orderStatusFilter == st;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(st),
                      selected: isSel,
                      onSelected: (val) {
                        setState(() => _orderStatusFilter = st);
                      },
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      checkmarkColor: AppColors.primaryDark,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? AppColors.primaryDark : AppColors.textMuted,
                      ),
                      backgroundColor: AppColors.sandBackground,
                      side: BorderSide(
                        color: isSel ? AppColors.primary : AppColors.sandBorder,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.sandBorder),

          // Lista de Órdenes
          Expanded(
            child: filteredOrders.isEmpty
                ? const Center(
                    child: Text('No hay pedidos con el filtro seleccionado', style: TextStyle(color: AppColors.textMuted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final clientName = (order.clienteNombre != null && order.clienteNombre!.isNotEmpty)
        ? order.clienteNombre!
        : 'Cliente PlayApp';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.sandBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.displayCode,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.deepNavy),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  order.fecha,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        clientName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (order.telefono != null && order.telefono!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(order.telefono!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
              ],
            ),
            if ((order.direccion != null && order.direccion!.isNotEmpty) || order.carpa != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.beach_access, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${order.direccion ?? ""} ${order.carpa != null ? "· Carpa: ${order.carpa}" : ""}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 18, color: AppColors.sandBorder),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    StatusBadge(label: order.estadoPedido, color: order.estadoPedidoColor),
                    StatusBadge(label: order.estadoPago, color: order.estadoPagoColor, isSmall: true),
                  ],
                ),
                Text(
                  CurrencyFormatter.formatCOP(order.total),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showChangeStatusDialog(order),
                    icon: const Icon(Icons.sync_alt, size: 16),
                    label: const Text('Estado', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!order.isPaid) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsPaid(order.id),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Cobrado', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.visibility_rounded, color: AppColors.primaryDark),
                  tooltip: 'Ver detalle de la orden',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => OrderDetailModal(order: order),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeStatusDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Actualizar Estado: ${order.displayCode}'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.inbox_rounded, color: AppColors.primary),
              title: const Text(OrderStatusConstants.recibido),
              onTap: () {
                Navigator.pop(ctx);
                _updateOrderStatus(order.id, OrderStatusConstants.recibido);
              },
            ),
            ListTile(
              leading: const Icon(Icons.outdoor_grill_rounded, color: AppColors.warning),
              title: const Text(OrderStatusConstants.enPreparacion),
              onTap: () {
                Navigator.pop(ctx);
                _updateOrderStatus(order.id, OrderStatusConstants.enPreparacion);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_rounded, color: AppColors.success),
              title: const Text(OrderStatusConstants.terminado),
              onTap: () {
                Navigator.pop(ctx);
                _updateOrderStatus(order.id, OrderStatusConstants.terminado);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_rounded, color: AppColors.danger),
              title: const Text(OrderStatusConstants.cancelado),
              onTap: () {
                Navigator.pop(ctx);
                _updateOrderStatus(order.id, OrderStatusConstants.cancelado);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
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

  Future<void> _markAsPaid(String orderId) async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final ok = await admin.markOrderAsPaid(orderId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido marcado como pagado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  // ==========================================
  // TAB 2: CATÁLOGO & PRODUCTOS
  // ==========================================
  Widget _buildCatalogTab(AdminProvider admin) {
    final prodProv = Provider.of<ProductProvider>(context);
    final allProducts = prodProv.products;

    final filtered = allProducts.where((p) {
      if (_productCategoryFilter == 0) return true;
      return p.categoriaId == _productCategoryFilter;
    }).toList();

    return Column(
      children: [
        // Barra superior con botón crear
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCatFilterChip('Todos', 0),
                      _buildCatFilterChip('Comidas', 1),
                      _buildCatFilterChip('Bebidas', 2),
                      _buildCatFilterChip('Servicios', 3),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showCreateProductDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nuevo', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.sandBorder),

        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('No hay productos en esta categoría', style: TextStyle(color: AppColors.textMuted)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return _buildProductAdminCard(product);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCatFilterChip(String label, int catId) {
    final isSel = _productCategoryFilter == catId;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSel,
        onSelected: (val) {
          setState(() => _productCategoryFilter = catId);
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primaryDark,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          color: isSel ? AppColors.primaryDark : AppColors.textMuted,
        ),
        backgroundColor: AppColors.sandBackground,
        side: BorderSide(color: isSel ? AppColors.primary : AppColors.sandBorder),
      ),
    );
  }

  Widget _buildProductAdminCard(ProductModel product) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.sandBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: ImageHelper.buildProductImage(
                  imageUrl: product.imageUrl,
                  imageSrc: product.imagenSrc,
                  productId: product.id,
                  assetFallback: product.localAssetFallback,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: product.stock > 0 ? AppColors.successBg : AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.stock > 0 ? 'Stock: ${product.stock}' : 'Agotado',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: product.stock > 0 ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.categoriaNombre,
                    style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.formatCOP(product.precio),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppColors.primaryDark, size: 20),
                  tooltip: 'Editar producto',
                  onPressed: () => _showEditProductDialog(product),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                  tooltip: 'Eliminar producto',
                  onPressed: () => _confirmDeleteProduct(product),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProductImage({
    required BuildContext context,
    required void Function(Uint8List bytes, String base64) onImagePicked,
  }) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final name = picked.name.toLowerCase();
      final ext = name.contains('.') ? name.split('.').last : '';
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Formato no permitido. Por favor selecciona una imagen JPG, PNG o WebP.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La imagen supera el límite de 5 MB permitido.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      final mime = ext == 'png'
          ? 'image/png'
          : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
      final base64Str = 'data:$mime;base64,${base64Encode(bytes)}';
      onImagePicked(bytes, base64Str);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No fue posible cargar la imagen seleccionada.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showCreateProductDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '10');
    int categoryId = 1;
    Uint8List? selectedImageBytes;
    String? selectedBase64;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nuevo Producto Playero', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        width: 140,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.sandBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sandBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: selectedImageBytes != null
                            ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.turquoise),
                                  SizedBox(height: 4),
                                  Text('Sin imagen', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                      ),
                      if (selectedImageBytes != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedImageBytes = null;
                                selectedBase64 = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      _pickProductImage(
                        context: context,
                        onImagePicked: (bytes, base64) {
                          setDialogState(() {
                            selectedImageBytes = bytes;
                            selectedBase64 = base64;
                          });
                        },
                      );
                    },
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(
                      selectedImageBytes != null ? 'Cambiar imagen' : 'Seleccionar imagen',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del plato o bebida', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción / Ingredientes', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Precio (COP)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock Inicial', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: categoryId,
                  decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
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
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                final stock = int.tryParse(stockCtrl.text.trim()) ?? 10;
                if (name.isEmpty || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor completa el nombre y precio válido.')),
                  );
                  return;
                }

                Navigator.pop(ctx);
                final admin = Provider.of<AdminProvider>(context, listen: false);
                final ok = await admin.createProduct(
                  nombre: name,
                  descripcion: descCtrl.text.trim(),
                  precio: price,
                  cantidad: stock,
                  categoriaId: categoryId,
                  base64Image: selectedBase64,
                );

                if (ok && mounted) {
                  Provider.of<ProductProvider>(context, listen: false).fetchProducts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Producto creado exitosamente'), backgroundColor: AppColors.success),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Crear Plato'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(ProductModel product) {
    final nameCtrl = TextEditingController(text: product.nombre);
    final descCtrl = TextEditingController(text: product.descripcion);
    final priceCtrl = TextEditingController(text: product.precio.toInt().toString());
    final stockCtrl = TextEditingController(text: product.stock.toString());
    int categoryId = product.categoriaId > 0 && product.categoriaId <= 3 ? product.categoriaId : 1;
    Uint8List? newImageBytes;
    String? newBase64;
    bool removeCurrentImage = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Editar: ${product.nombre}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        width: 140,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.sandBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sandBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: newImageBytes != null
                            ? Image.memory(newImageBytes!, fit: BoxFit.cover)
                            : (removeCurrentImage
                                ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.no_photography_outlined, size: 36, color: AppColors.textMuted),
                                      SizedBox(height: 4),
                                      Text('Sin imagen', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    ],
                                  )
                                : ImageHelper.buildProductImage(
                                    imageSrc: product.imagenSrc,
                                    imageUrl: product.imageUrl,
                                    productId: product.id,
                                    assetFallback: product.localAssetFallback,
                                    fit: BoxFit.cover,
                                  )),
                      ),
                      if (newImageBytes != null || (!removeCurrentImage && (product.hasImage || product.imagenSrc != null)))
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                newImageBytes = null;
                                newBase64 = null;
                                removeCurrentImage = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _pickProductImage(
                          context: context,
                          onImagePicked: (bytes, base64) {
                            setDialogState(() {
                              newImageBytes = bytes;
                              newBase64 = base64;
                              removeCurrentImage = false;
                            });
                          },
                        );
                      },
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(
                        (newImageBytes != null || (!removeCurrentImage && (product.hasImage || product.imagenSrc != null)))
                            ? 'Cambiar imagen'
                            : 'Seleccionar imagen',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    if (!removeCurrentImage && (product.hasImage || product.imagenSrc != null || newImageBytes != null)) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            newImageBytes = null;
                            newBase64 = null;
                            removeCurrentImage = true;
                          });
                        },
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                        label: const Text('Eliminar', style: TextStyle(fontSize: 13, color: AppColors.danger)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Precio (COP)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: categoryId,
                  decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
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
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? product.precio;
                final stock = int.tryParse(stockCtrl.text.trim()) ?? product.stock;

                Navigator.pop(ctx);
                final admin = Provider.of<AdminProvider>(context, listen: false);
                final ok = await admin.updateProduct(
                  id: product.id,
                  nombre: name,
                  descripcion: descCtrl.text.trim(),
                  precio: price,
                  cantidad: stock,
                  categoriaId: categoryId,
                  base64Image: newBase64,
                  removeImage: removeCurrentImage,
                );

                if (ok && mounted) {
                  Provider.of<ProductProvider>(context, listen: false).fetchProducts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Producto actualizado exitosamente'), backgroundColor: AppColors.success),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Producto?'),
        content: Text('¿Estás seguro de eliminar permanentemente "${product.nombre}" del catálogo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final admin = Provider.of<AdminProvider>(context, listen: false);
              final ok = await admin.deleteProduct(product.id);
              if (ok && mounted) {
                Provider.of<ProductProvider>(context, listen: false).fetchProducts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Producto eliminado'), backgroundColor: AppColors.danger),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: CLIMA Y OCUPACIÓN EN BOCAGRANDE
  // ==========================================
  Widget _buildWeatherTab(AdminProvider admin) {
    final weather = admin.weather;

    return RefreshIndicator(
      onRefresh: () async => admin.fetchMetrics(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card de Clima
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.deepNavy, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepNavy.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.turquoise,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'En vivo · Playa de Bocagrande',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        weather?.isNight == true ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                        color: AppColors.warning,
                        size: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    weather?.temperature ?? '30,0 °C',
                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (weather?.description ?? 'Cielo claro').toUpperCase(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  if (weather != null && weather.feelsLike.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Sensación térmica: ${weather.feelsLike}',
                      style: const TextStyle(fontSize: 13, color: Colors.white60),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Métricas Detalladas
            const Text(
              'Condiciones Atmosféricas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.1,
              children: [
                _buildWeatherMiniCard(Icons.air, 'Viento', weather?.wind ?? '17,7 km/h', AppColors.primary),
                _buildWeatherMiniCard(Icons.water_drop, 'Humedad', weather?.humidity ?? '74,0 %', AppColors.turquoise),
                _buildWeatherMiniCard(Icons.cloud, 'Nubosidad', weather?.clouds ?? '0,0 %', Colors.blueGrey),
                _buildWeatherMiniCard(Icons.visibility, 'Visibilidad', weather?.visibility ?? '10,0 km', AppColors.warning),
                _buildWeatherMiniCard(Icons.speed, 'Presión', weather?.pressure ?? '1007,0 hPa', Colors.indigo),
                _buildWeatherMiniCard(Icons.wb_twilight, 'Sol', '↑ ${weather?.sunrise ?? "05:58"} · ↓ ${weather?.sunset ?? "17:36"}', AppColors.coral),
              ],
            ),
            const SizedBox(height: 24),

            // Ocupación Estimada
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
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
                      const Expanded(
                        child: Text(
                          'Ocupación Estimada en Playa',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.deepNavy),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (weather?.prediction != null ? AppColors.turquoise : AppColors.primary).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          weather?.prediction != null ? 'Red neuronal' : 'Según Clima',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: weather?.prediction != null ? const Color(0xFF0F766E) : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Prioridad: red neuronal en vivo > rango por reglas > sin datos del clima.
                      final occupationRange = weather?.prediction != null
                          ? weather!.prediction!.formatted
                          : (weather?.estimate != null)
                              ? '${weather!.estimate!.minimum} % – ${weather.estimate!.maximum} %'
                              : 'Sin datos';
                      final conditionText = weather?.estimate?.condition ??
                          (weather?.isNight == true ? 'Noche' : 'Condición óptima');

                      final isNarrow = constraints.maxWidth < 280;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                occupationRange,
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              conditionText,
                              style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      }

                      return Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              occupationRange,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                            ),
                          ),
                          Text(
                            conditionText,
                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: weather?.prediction != null
                        ? (weather!.prediction!.percentage / 100.0).clamp(0.02, 1.0)
                        : (weather?.estimate != null)
                            ? (weather!.estimate!.maximum / 100.0).clamp(0.02, 1.0)
                            : 0.0,
                    backgroundColor: AppColors.sandBackground,
                    color: AppColors.turquoise,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  if (weather?.prediction != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      weather!.estimate != null
                          ? 'Estimación de la red neuronal con el clima, la hora y el calendario actuales. '
                              'Reglas de respaldo: ${weather.estimate!.minimum} % – ${weather.estimate!.maximum} %.'
                          : 'Estimación de la red neuronal con el clima, la hora y el calendario actuales.',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.35),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    weather?.estimate?.summary ??
                        'No fue posible obtener el clima en vivo. Desliza hacia abajo para actualizar.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textMain, height: 1.4),
                  ),
                  if (weather?.estimate?.explanation != null &&
                      weather!.estimate!.explanation.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.sandBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        weather.estimate!.explanation,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Análisis de la red neuronal (gráficas interactivas)
            const OccupancyAnalyticsSection(),
            const SizedBox(height: 24),

            // Mapa de Monitoreo
            const Text(
              'Ubicación de Monitoreo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
            ),
            const SizedBox(height: 10),
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sandBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(weather?.latitude ?? 10.399667, weather?.longitude ?? -75.555001),
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.proyecto.playapp',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(weather?.latitude ?? 10.399667, weather?.longitude ?? -75.555001),
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.danger,
                          size: 42,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherMiniCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: PREDICCIÓN IA CON WEKA
  // ==========================================
  Widget _buildPredictionTab(AdminProvider admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sandBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppColors.primaryDark, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modelo Predictivo Weka',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.deepNavy),
                          ),
                          Text(
                            'Estima la demanda de productos en playa',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.sandBorder),

                // Formulario de parámetros
                const Text('Día de la Semana', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _predDiaSemana,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'].map((d) {
                    return DropdownMenuItem(value: d, child: Text(d));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _predDiaSemana = v);
                  },
                ),
                const SizedBox(height: 14),

                const Text('Producto Objetivo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _predProducto,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: [
                    'Cerveza Club Colombia',
                    'Ceviche de camaron',
                    'Clase de surf',
                    'Alquiler de moto acuática',
                    'Coco frio',
                    'Coctel de maracuya',
                    'Pescado frito',
                    'Ostras frescas',
                    'Limonada de coco',
                    'Tinto frio',
                  ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _predProducto = v);
                  },
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _predCategoria,
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                            items: ['Bebida', 'Comida', 'Servicio'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _predCategoria = v);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Precio COP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _predPrecioCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Clima', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _predClima,
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                            items: ['Soleado', 'Nublado', 'Lluvioso'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _predClima = v);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Temporada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _predTemporada,
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                            items: ['Alta', 'Baja', 'Normal'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _predTemporada = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: admin.isPredicting
                        ? null
                        : () async {
                            final precio = int.tryParse(_predPrecioCtrl.text.trim()) ?? 8000;
                            await admin.predictSales(
                              diaSemana: _predDiaSemana,
                              producto: _predProducto,
                              categoria: _predCategoria,
                              precio: precio,
                              clima: _predClima,
                              temporada: _predTemporada,
                            );
                          },
                    icon: admin.isPredicting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.bolt_rounded),
                    label: Text(admin.isPredicting ? 'Calculando con IA...' : 'Calcular Proyección de Ventas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tarjeta de Resultado
          if (admin.lastPredictionResult != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.turquoiseLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.turquoise),
              ),
              child: Column(
                children: [
                  const Icon(Icons.insights_rounded, color: AppColors.deepNavy, size: 36),
                  const SizedBox(height: 8),
                  const Text(
                    'Demanda Estimada',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.deepNavy),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${admin.lastPredictionResult!['unidades']} Unidades',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.deepNavy),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Para "${admin.lastPredictionResult!['producto']}" en día $_predDiaSemana con clima $_predClima.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.deepNavy),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TAB 5: USUARIOS & ADMINISTRADORES
  // ==========================================
  Widget _buildUsersTab(AdminProvider admin) {
    final allUsers = admin.users;
    final filtered = allUsers.where((u) {
      if (_userRoleFilter == 'Admins') return u.esAdmin;
      if (_userRoleFilter == 'Clientes') return !u.esAdmin;
      return true;
    }).toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Todos', 'Admins', 'Clientes'].map((r) {
                      final isSel = _userRoleFilter == r;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(r),
                          selected: isSel,
                          onSelected: (val) {
                            setState(() => _userRoleFilter = r);
                          },
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primaryDark,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? AppColors.primaryDark : AppColors.textMuted,
                          ),
                          backgroundColor: AppColors.sandBackground,
                          side: BorderSide(color: isSel ? AppColors.primary : AppColors.sandBorder),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateAdminDialog,
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Crear Admin', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.sandBorder),

        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No hay usuarios en este segmento', style: TextStyle(color: AppColors.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final u = filtered[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.sandBorder),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: u.esAdmin ? AppColors.primaryDark : AppColors.sandBorder,
                          foregroundColor: u.esAdmin ? Colors.white : AppColors.deepNavy,
                          child: Text(
                            u.nombre.isNotEmpty ? u.nombre.substring(0, 1).toUpperCase() : 'U',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(u.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(u.correo, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: u.esAdmin ? AppColors.primary.withOpacity(0.12) : AppColors.sandBackground,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: u.esAdmin ? AppColors.primary : AppColors.sandBorder),
                          ),
                          child: Text(
                            u.esAdmin ? 'ADMIN' : 'CLIENTE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: u.esAdmin ? AppColors.primaryDark : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showCreateAdminDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Registrar Nuevo Administrador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña de Acceso', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final email = emailCtrl.text.trim();
              final pass = passCtrl.text.trim();

              if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor completa todos los campos obligatorios.')),
                );
                return;
              }

              Navigator.pop(ctx);
              final admin = Provider.of<AdminProvider>(context, listen: false);
              final ok = await admin.createAdminUser(
                nombreCompleto: name,
                correo: email,
                password: pass,
              );

              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Administrador creado exitosamente'), backgroundColor: AppColors.success),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error creando administrador. Verifica el correo.'), backgroundColor: AppColors.danger),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 6: RESEÑAS & MODERACIÓN
  // ==========================================
  Widget _buildReviewsTab(AdminProvider admin) {
    final reviews = admin.adminReviews;

    return RefreshIndicator(
      onRefresh: () async => admin.fetchAdminReviews(),
      child: reviews.isEmpty
          ? const Center(child: Text('No hay reseñas registradas', style: TextStyle(color: AppColors.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final r = reviews[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.sandBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                r.nombre,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < r.valoracion ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: AppColors.warning,
                                  size: 16,
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r.comentario,
                          style: const TextStyle(fontSize: 13, color: AppColors.textMain, height: 1.3),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                r.fechaFormateada,
                                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                              ),
                              InkWell(
                                onTap: () => _confirmDeleteReview(r),
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.delete_outline, size: 15, color: AppColors.danger),
                                      SizedBox(width: 4),
                                      Text(
                                        'Eliminar',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmDeleteReview(ReviewModel review) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Reseña?'),
        content: Text('¿Deseas eliminar la opinión de "${review.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final admin = Provider.of<AdminProvider>(context, listen: false);
              final ok = await admin.deleteAdminReview(review.id);
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reseña eliminada'), backgroundColor: AppColors.danger),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
