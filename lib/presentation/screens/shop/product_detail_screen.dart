import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../widgets/custom_app_bar.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  Widget _buildImage() {
    final p = widget.product;
    if (p.imagenSrc != null && p.imagenSrc!.contains(',')) {
      try {
        final bytes = base64Decode(p.imagenSrc!.split(',').last);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {}
    }

    final asset = p.localAssetFallback;
    if (asset != null) {
      return Image.asset(asset, fit: BoxFit.cover);
    }

    if (p.imagenUrl != null && p.imagenUrl!.startsWith('http')) {
      return Image.network(p.imagenUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset(AppAssets.placeholder));
    }

    return Image.asset(AppAssets.placeholder, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: CustomAppBar(title: p.nombre),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen grande
            SizedBox(
              height: 280,
              width: double.infinity,
              child: _buildImage(),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.categoriaId == 1 ? AppColors.primary : AppColors.warning,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p.categoriaNombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        p.cantidadDisponible > 0
                            ? 'Disponible (${p.cantidadDisponible} un.)'
                            : 'Agotado',
                        style: TextStyle(
                          color: p.cantidadDisponible > 0 ? AppColors.success : AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.formatCOP(p.precio),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'Descripción del Plato / Servicio',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.descripcion.isNotEmpty
                        ? p.descripcion
                        : 'Disfruta de este producto elaborado con los mejores ingredientes y estándares de higiene para tu estadía en la playa de Cartagena.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Garantía PlayApp
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.turquoiseLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.turquoise.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.verified, color: AppColors.turquoise, size: 24),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Garantía PlayApp: Precio verificado sin cobros sorpresa ni propinas no autorizadas.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.deepNavy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Selector de cantidad y Agregar al carrito
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.sandBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                              icon: const Icon(Icons.remove, size: 18),
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              onPressed: _quantity < p.cantidadDisponible ? () => setState(() => _quantity++) : null,
                              icon: const Icon(Icons.add, size: 18),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: p.cantidadDisponible > 0
                              ? () {
                                  cart.addToCart(p, quantity: _quantity);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('¡$_quantity ${p.nombre} agregado al carrito!'),
                                      backgroundColor: AppColors.primaryDark,
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              : null,
                          icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                          label: Text(
                            'Agregar (${CurrencyFormatter.formatCOP(p.precio * _quantity)})',
                            style: const TextStyle(fontSize: 14),
                          ),
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
}
