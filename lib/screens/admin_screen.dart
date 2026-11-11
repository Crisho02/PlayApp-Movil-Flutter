import 'package:flutter/material.dart';
import '../models/pedido.dart';
import '../models/producto.dart';
import '../state/playapp_state.dart';
import '../theme/playapp_theme.dart';
import '../widgets/playapp_badges.dart';

/// Panel administrativo (`Management/`): métricas, órdenes, catálogo y predicción.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  String _diaSemana = 'Sabado';
  CategoriaProducto _predCategoria = CategoriaProducto.comida;
  String _clima = 'Soleado';
  String _temporada = 'Alta';
  final _precioPredCtrl = TextEditingController(text: '32000');
  double? _resultadoPrediccion;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _precioPredCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = PlayAppScope.of(context);

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: PlayAppColors.primaryBlue,
            unselectedLabelColor: PlayAppColors.mutedText,
            indicatorColor: PlayAppColors.primaryBlue,
            tabs: const [
              Tab(icon: Icon(Icons.speed), text: 'Dashboard'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Órdenes'),
              Tab(icon: Icon(Icons.inventory_2), text: 'Catálogo'),
              Tab(icon: Icon(Icons.trending_up), text: 'Predicción'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardTab(state),
              _buildOrdersTab(state),
              _buildCatalogTab(state),
              _buildPredictionTab(state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardTab(PlayAppState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PlayAppColors.infoCyan.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Panel administrativo · ${state.currentUser?.nombreCompleto ?? "Restaurante"}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _MetricCard(label: 'Pedidos', value: '${state.pedidos.length}'),
            _MetricCard(
              label: 'Ingresos',
              value: formatCop(state.ingresosTotales),
              color: PlayAppColors.successGreen,
            ),
            _MetricCard(
              label: 'Productos',
              value: '${state.productos.length}',
              color: PlayAppColors.primaryBlue,
            ),
            _MetricCard(
              label: 'Inventario',
              value: formatCop(state.valorInventario),
            ),
            _MetricCard(
              label: 'Calificación',
              value: '${state.calificacionPromedio.toStringAsFixed(1)} ★',
              color: const Color(0xFFD97706),
            ),
            _MetricCard(
              label: 'Reseñas',
              value: '${state.resenas.length}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrdersTab(PlayAppState state) {
    final pedidos = state.pedidos;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
      itemCount: pedidos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final pedido = pedidos[idx];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${pedido.id} · ${pedido.clienteNombre}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      formatCop(pedido.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: PlayAppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    PlayAppPillBadge(
                      label: pedido.estado.etiqueta,
                      backgroundColor: pedido.estado.color,
                      textColor: pedido.estado.textColor,
                    ),
                    PlayAppPillBadge(
                      label: 'Pago: ${pedido.pago.estado.etiqueta}',
                      backgroundColor: pedido.pago.estado.color,
                      textColor: pedido.pago.estado.textColor,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => state.actualizarEstadoPedido(
                        pedido.id,
                        EstadoPedido.enPreparacion,
                      ),
                      icon: const Icon(Icons.hourglass_bottom, size: 16),
                      label: const Text('Preparando'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => state.actualizarEstadoPedido(
                        pedido.id,
                        EstadoPedido.terminado,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PlayAppColors.successGreen,
                      ),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Terminar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCatalogTab(PlayAppState state) {
    final productos = state.productos;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _openProductDialog(state),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Producto'),
          ),
        ),
        const SizedBox(height: 10),
        ...productos.map((p) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  p.imagenAsset,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                p.nombre,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${p.categoria.etiqueta} · ${formatCop(p.precio)} · Stock: ${p.stock}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: PlayAppColors.primaryBlue),
                    onPressed: () => _openProductDialog(state, producto: p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: PlayAppColors.dangerRed),
                    onPressed: () => state.eliminarProducto(p.id),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPredictionTab(PlayAppState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
      children: [
        const Text(
          'Predicción de Ventas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Simulador inspirado en el módulo Weka de PlayApp para proyectar demanda esperada.',
          style: TextStyle(color: PlayAppColors.mutedText),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _diaSemana,
          decoration: const InputDecoration(labelText: 'Día de la Semana'),
          items: const [
            'Lunes',
            'Martes',
            'Miercoles',
            'Jueves',
            'Viernes',
            'Sabado',
            'Domingo',
          ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _diaSemana = v);
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<CategoriaProducto>(
          initialValue: _predCategoria,
          decoration: const InputDecoration(labelText: 'Categoría'),
          items: CategoriaProducto.values
              .map((c) => DropdownMenuItem(value: c, child: Text(c.etiqueta)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _predCategoria = v);
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _precioPredCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Precio (COP)'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _clima,
          decoration: const InputDecoration(labelText: 'Clima'),
          items: const ['Soleado', 'Nublado', 'Lluvioso']
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _clima = v);
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _temporada,
          decoration: const InputDecoration(labelText: 'Temporada'),
          items: const ['Alta', 'Normal', 'Baja']
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _temporada = v);
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            final precio = double.tryParse(_precioPredCtrl.text.trim()) ?? 25000;
            final res = state.predecirVenta(
              diaSemana: _diaSemana,
              categoria: _predCategoria,
              precio: precio,
              clima: _clima,
              temporada: _temporada,
            );
            setState(() => _resultadoPrediccion = res);
          },
          icon: const Icon(Icons.analytics),
          label: const Text('Calcular Predicción'),
        ),
        if (_resultadoPrediccion != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PlayAppColors.infoCyan.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PlayAppColors.infoCyan),
            ),
            child: Text(
              'Resultado estimado: ${_resultadoPrediccion!.toStringAsFixed(2)} unidades proyectadas',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openProductDialog(
    PlayAppState state, {
    Producto? producto,
  }) async {
    final nameCtrl = TextEditingController(text: producto?.nombre ?? '');
    final descCtrl = TextEditingController(text: producto?.descripcion ?? '');
    final priceCtrl = TextEditingController(
      text: producto != null ? producto.precio.round().toString() : '15000',
    );
    final stockCtrl = TextEditingController(
      text: producto != null ? producto.stock.toString() : '20',
    );
    var cat = producto?.categoria ?? CategoriaProducto.comida;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: Text(
                producto == null ? 'Nuevo Producto' : 'Editar Producto',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<CategoriaProducto>(
                      initialValue: cat,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: CategoriaProducto.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.etiqueta),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDlgState(() => cat = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Precio (COP)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock'),
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
                  onPressed: () {
                    final nombre = nameCtrl.text.trim();
                    if (nombre.isEmpty) return;
                    state.guardarProducto(
                      id: producto?.id,
                      nombre: nombre,
                      descripcion: descCtrl.text.trim().isEmpty
                          ? 'Producto de PlayApp'
                          : descCtrl.text.trim(),
                      precio: double.tryParse(priceCtrl.text.trim()) ?? 15000,
                      stock: int.tryParse(stockCtrl.text.trim()) ?? 10,
                      categoria: cat,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.color = const Color(0xFF1E293B),
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: PlayAppColors.mutedText,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
