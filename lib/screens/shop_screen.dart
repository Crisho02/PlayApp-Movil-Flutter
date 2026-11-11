import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../state/playapp_state.dart';
import '../theme/playapp_theme.dart';
import '../widgets/playapp_badges.dart';

/// Tienda (`tienda.html`): búsqueda, filtro por categoría, ordenamiento y carrito.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _searchController = TextEditingController();
  OrdenTienda _orden = OrdenTienda.nombreAsc;
  final Map<String, int> _cantidades = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _cantidadPara(String productoId) => _cantidades[productoId] ?? 1;

  void _cambiarCantidad(Producto producto, int delta) {
    final actual = _cantidadPara(producto.id);
    final siguiente = actual + delta;
    if (siguiente < 1) return;
    if (siguiente > producto.stock) {
      _mostrarMensaje(
        'Solo hay ${producto.stock} unidades disponibles de ${producto.nombre}.',
        esError: true,
      );
      return;
    }
    setState(() => _cantidades[producto.id] = siguiente);
  }

  void _agregarProducto(PlayAppState state, Producto producto) {
    final cantidad = _cantidadPara(producto.id);
    final error = state.agregarAlCarrito(producto, cantidad);
    if (error != null) {
      _mostrarMensaje(error, esError: true);
      return;
    }
    setState(() => _cantidades[producto.id] = 1);
    _mostrarMensaje('¡Producto añadido al carrito de compras!');
  }

  void _mostrarMensaje(String texto, {bool esError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                esError ? Icons.cancel : Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(texto)),
            ],
          ),
          backgroundColor:
              esError ? PlayAppColors.dangerRed : PlayAppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = PlayAppScope.of(context);
    final selectedCat = state.shopCategoryFilter;
    final productos = state.filtrarProductos(
      query: _searchController.text,
      categoria: selectedCat,
      orden: _orden,
    );

    return Column(
      children: [
        _buildFilterBar(state, selectedCat),
        Expanded(
          child: productos.isEmpty
              ? _buildEmptyResults(state)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 900
                        ? 3
                        : constraints.maxWidth >= 560
                            ? 2
                            : 1;
                    if (crossAxisCount == 1) {
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
                        itemCount: productos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) => _buildProductCard(
                          state,
                          productos[idx],
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 360,
                      ),
                      itemCount: productos.length,
                      itemBuilder: (context, idx) => _buildProductCard(
                        state,
                        productos[idx],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(
    PlayAppState state,
    CategoriaProducto? selectedCat,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Producto ...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: PlayAppColors.cardBorder),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: DropdownButton<OrdenTienda>(
                    value: _orden,
                    items: OrdenTienda.values.map((o) {
                      return DropdownMenuItem(
                        value: o,
                        child: Text(o.etiqueta, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _orden = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: selectedCat == null,
                  onSelected: (_) => state.setShopCategoryFilter(null),
                ),
                const SizedBox(width: 6),
                ...CategoriaProducto.values.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text('${cat.etiqueta}s'),
                      selected: selectedCat == cat,
                      onSelected: (_) => state.setShopCategoryFilter(cat),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(PlayAppState state, Producto producto) {
    final qty = _cantidadPara(producto.id);
    final outOfStock = producto.stock <= 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showProductDetail(state, producto),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 158,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    producto.imagenAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Image.asset(
                      'assets/images/blank-product.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: PlayAppPillBadge(
                      label: producto.categoria.etiqueta,
                      backgroundColor: producto.categoria.badgeColor,
                      textColor: producto.categoria.textColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCop(producto.precio),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: PlayAppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    outOfStock
                        ? 'Agotado temporalmente'
                        : 'Disponible: ${producto.stock} unidades.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: outOfStock
                          ? PlayAppColors.dangerRed
                          : const Color(0xFF334155),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    producto.entidadNombre,
                    style: const TextStyle(
                      fontSize: 12,
                      color: PlayAppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: PlayAppColors.primaryBlue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                              padding: EdgeInsets.zero,
                              onPressed: outOfStock ? null : () => _cambiarCantidad(producto, -1),
                              icon: const Icon(Icons.remove, size: 17),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '$qty',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                              padding: EdgeInsets.zero,
                              onPressed: outOfStock ? null : () => _cambiarCantidad(producto, 1),
                              icon: const Icon(Icons.add, size: 17),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: outOfStock
                              ? null
                              : () => _agregarProducto(state, producto),
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Agregar'),
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

  void _showProductDetail(PlayAppState state, Producto producto) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  producto.imagenAsset,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      producto.nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  PlayAppPillBadge(
                    label: producto.categoria.etiqueta,
                    backgroundColor: producto.categoria.badgeColor,
                    textColor: producto.categoria.textColor,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${formatCop(producto.precio)} · ${producto.entidadNombre}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PlayAppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                producto.descripcion,
                style: const TextStyle(fontSize: 14.5, height: 1.4),
              ),
              const SizedBox(height: 10),
              Text(
                'Disponible: ${producto.stock} unidades',
                style: const TextStyle(color: PlayAppColors.mutedText),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: producto.stock <= 0
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _agregarProducto(state, producto);
                        },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Añadir al carrito'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyResults(PlayAppState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 54, color: PlayAppColors.mutedText),
            const SizedBox(height: 10),
            const Text(
              'No encontramos productos con ese filtro.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                state.setShopCategoryFilter(null);
                setState(() {});
              },
              child: const Text('Limpiar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}
