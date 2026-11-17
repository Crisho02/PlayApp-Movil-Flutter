import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/image_helper.dart';
import '../../../providers/cart_provider.dart';
import '../../widgets/custom_app_bar.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Carrito de Compras', showCart: false),
      body: cart.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppColors.sandBackground,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 72,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tu carrito está vacío',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Explora nuestro menú y pide lo mejor de Cartagena directo a tu toalla o carpa.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/shop',
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.storefront, size: 20),
                      label: const Text('Explorar Tienda'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.itemsList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cart.itemsList[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.sandBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 70,
                                height: 70,
                                child: ImageHelper.buildProductImage(
                                  imageSrc: item.imagenSrc,
                                  imageUrl: item.imagenUrl,
                                  productId: item.productoId,
                                  assetFallback: item.assetFallback,
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
                                    item.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textMain,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.formatCOP(item.precio),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppColors.sandBorder),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: () => cart.updateQuantity(item.productoId, item.cantidad - 1),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                child: Icon(Icons.remove, size: 14, color: AppColors.textMuted),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text(
                                                '${item.cantidad}',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => cart.updateQuantity(item.productoId, item.cantidad + 1),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                child: Icon(Icons.add, size: 14, color: AppColors.textMuted),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        CurrencyFormatter.formatCOP(item.subtotal),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: AppColors.deepNavy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                              onPressed: () => cart.removeFromCart(item.productoId),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Resumen y botón Checkout
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                          Text(
                            CurrencyFormatter.formatCOP(cart.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.beach_access, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('Envío a la playa:', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                            ],
                          ),
                          Text(
                            CurrencyFormatter.formatCOP(cart.shippingFee),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total a Pagar:',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: AppColors.deepNavy,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatCOP(cart.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/checkout-shipment');
                          },
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('Continuar a Entrega en Playa'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
