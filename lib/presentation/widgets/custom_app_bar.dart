import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/cart_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showCart;
  final VoidCallback? onCartPressed;
  final List<Widget>? extraActions;

  const CustomAppBar({
    super.key,
    this.title,
    this.showCart = true,
    this.onCartPressed,
    this.extraActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
      leadingWidth: 48,
      title: title != null
          ? Text(title!)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    AppAssets.logo,
                    height: 28,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.beach_access,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'PLAYAPP',
                  style: TextStyle(
                    color: AppColors.deepNavy,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.turquoiseLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'CARTAGENA',
                    style: TextStyle(
                      color: AppColors.turquoise,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
      actions: [
        if (extraActions != null) ...extraActions!,
        if (showCart)
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              final count = cart.itemCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.primaryDark,
                      size: 24,
                    ),
                    onPressed: onCartPressed ??
                        () {
                          Navigator.pushNamed(context, '/cart');
                        },
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}
