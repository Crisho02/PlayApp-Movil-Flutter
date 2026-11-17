import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/product_card.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProv = Provider.of<ProductProvider>(context);
    final cartProv = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Tienda Playera'),
      body: Column(
        children: [
          // Barra de Búsqueda y Ordenamiento
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => productProv.setSearchQuery(val),
                        decoration: InputDecoration(
                          hintText: 'Buscar comida, bebida o servicio...',
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                          suffixIcon: productProv.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => productProv.setSearchQuery(''),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sandBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: productProv.sortBy,
                          icon: const Icon(Icons.sort, color: AppColors.primary, size: 20),
                          items: const [
                            DropdownMenuItem(value: 'default', child: Text('Relevancia', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'price_asc', child: Text('Precio: \$ - \$\$', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'price_desc', child: Text('Precio: \$\$ - \$', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'name_asc', child: Text('Nombre (A-Z)', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (v) {
                            if (v != null) productProv.setSortBy(v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filtros de categoría en píldoras horizontales
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryPill(context, label: 'Todos', categoryId: 0, current: productProv.selectedCategory),
                      const SizedBox(width: 8),
                      _buildCategoryPill(context, label: 'Comidas', categoryId: 1, current: productProv.selectedCategory),
                      const SizedBox(width: 8),
                      _buildCategoryPill(context, label: 'Bebidas', categoryId: 2, current: productProv.selectedCategory),
                      const SizedBox(width: 8),
                      _buildCategoryPill(context, label: 'Servicios', categoryId: 3, current: productProv.selectedCategory),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Grid de Productos
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => productProv.fetchProducts(),
              color: AppColors.primary,
              child: Builder(
                builder: (context) {
                  if (productProv.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final products = productProv.filteredProducts;
                  if (products.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textLight),
                              const SizedBox(height: 12),
                              const Text(
                                'No se encontraron productos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Intenta con otro término o categoría',
                                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  productProv.setSearchQuery('');
                                  productProv.setCategory(0);
                                },
                                child: const Text('Limpiar Filtros'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.60,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        onAddToCart: (qty) => cartProv.addToCart(product, quantity: qty),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/product-detail',
                            arguments: product,
                          );
                        },
                      );
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

  Widget _buildCategoryPill(
    BuildContext context, {
    required String label,
    required int categoryId,
    required int current,
  }) {
    final isSelected = categoryId == current;
    final prov = Provider.of<ProductProvider>(context, listen: false);

    return InkWell(
      onTap: () => prov.setCategory(categoryId),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
}
