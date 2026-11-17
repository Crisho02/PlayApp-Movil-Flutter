import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import 'product_card.dart';

class ResponsiveProductGrid extends StatelessWidget {
  final List<ProductModel> products;
  final Function(ProductModel product, int quantity) onAddToCart;
  final Function(ProductModel product)? onTapProduct;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;

  const ResponsiveProductGrid({
    super.key,
    required this.products,
    required this.onAddToCart,
    this.onTapProduct,
    this.physics,
    this.shrinkWrap = false,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        const double spacing = 12;

        if (width < 340) {
          // En pantallas ultra estrechas (<340px) 1 columna previene cualquier desborde
          crossAxisCount = 1;
        } else if (width < 650) {
          // Móvil estándar: 2 columnas limpias
          crossAxisCount = 2;
        } else if (width < 950) {
          // Tablet o móvil horizontal: 3 columnas
          crossAxisCount = 3;
        } else if (width < 1250) {
          // Escritorio / Laptop: 4 columnas
          crossAxisCount = 4;
        } else {
          // Pantallas grandes: 5 columnas
          crossAxisCount = 5;
        }

        final double horizontalPadding = padding.horizontal;
        final double itemWidth =
            (width - horizontalPadding - (spacing * (crossAxisCount - 1))) /
                crossAxisCount;

        // Proporción exacta según contenido real para evitar áreas blancas vacías:
        // - Imagen (relación 4:3): itemWidth * 0.75
        // - Textos y botones compactos: ~118px
        final double estimatedCardHeight = (itemWidth * 0.75) + 118;
        final double childAspectRatio = itemWidth / estimatedCardHeight;

        final Widget grid = GridView.builder(
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              onAddToCart: (qty) => onAddToCart(product, qty),
              onTap: onTapProduct != null ? () => onTapProduct!(product) : null,
            );
          },
        );

        if (width > 1200) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: grid,
            ),
          );
        }

        return grid;
      },
    );
  }
}
