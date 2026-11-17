import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/image_helper.dart';
import '../../data/models/product_model.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final Function(int quantity) onAddToCart;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
    this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int _quantity = 1;

  void _increment() {
    if (_quantity < widget.product.cantidadDisponible) {
      setState(() {
        _quantity++;
      });
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isComida = p.categoriaId == 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sandBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagen con proporción uniforme 4:3 y etiqueta de categoría
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ImageHelper.buildProductImage(
                        imageSrc: p.imagenSrc,
                        imageUrl: p.imagenUrl,
                        productId: p.id,
                        assetFallback: p.localAssetFallback,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isComida ? AppColors.primaryDark : AppColors.warning,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.categoriaNombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Contenido con textos flexibles y límites para prevenir overflows
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textMain,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatCOP(p.precio),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.isAvailable
                          ? 'Disponible: ${p.cantidadDisponible}'
                          : 'Agotado',
                      style: TextStyle(
                        fontSize: 11,
                        color: p.isAvailable ? AppColors.textMuted : AppColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Selector de cantidad y botón agregar responsive
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.sandBorder),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: _decrement,
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                                  child: Icon(Icons.remove, size: 14, color: AppColors.textMuted),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: _increment,
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                                  child: Icon(Icons.add, size: 14, color: AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: p.isAvailable
                                ? () {
                                    widget.onAddToCart(_quantity);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('¡${p.nombre} agregado!'),
                                        duration: const Duration(milliseconds: 1200),
                                        backgroundColor: AppColors.primaryDark,
                                      ),
                                    );
                                  }
                                : null,
                            child: const Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.white),
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
      ),
    );
  }
}
