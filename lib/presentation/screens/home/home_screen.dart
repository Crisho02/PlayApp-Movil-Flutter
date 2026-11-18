import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/responsive_product_grid.dart';

class HomeScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _carouselCtrl = PageController();
  int _currentSlide = 0;
  Timer? _timer;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Hamburguesa de la casa',
      'tag': 'Platos Fuertes & Delivery en Playa',
      'desc': 'Carne artesanal, queso fundido y vegetales frescos servidos directamente en tu carpa o toalla.',
      'btn': 'Pedir Comida en Playa',
      'image': AppAssets.burger,
      'category': '1',
    },
    {
      'title': 'Pescado frito cartagenero',
      'tag': 'Especialidad Costeña',
      'desc': 'Mojarra roja recién salida del mar con patacón crocante, arroz de coco y ensalada.',
      'btn': 'Ver Menú de Mar',
      'image': AppAssets.pescado,
      'category': '1',
    },
    {
      'title': 'Bebidas Heladas & Cócteles',
      'tag': 'Refresca tu Tarde de Sol',
      'desc': 'Limonadas de coco frappé, cervezas nacionales y jugos tropicales en la brisa de Cartagena.',
      'btn': 'Pedir Bebidas Frías',
      'image': AppAssets.bebidas,
      'category': '2',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_carouselCtrl.hasClients) {
        int next = (_currentSlide + 1) % _slides.length;
        _carouselCtrl.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _carouselCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProv = Provider.of<ProductProvider>(context);
    final cartProv = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: () => productProv.fetchProducts(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Carousel
              SizedBox(
                height: 300,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _carouselCtrl,
                      onPageChanged: (i) => setState(() => _currentSlide = i),
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              slide['image']!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: AppColors.deepNavy),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.2),
                                    Colors.black.withOpacity(0.75),
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.35),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.turquoise,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          slide['tag']!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        slide['title']!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        slide['desc']!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          minimumSize: Size.zero,
                                        ),
                                        onPressed: () {
                                          productProv.setCategory(int.parse(slide['category']!));
                                          widget.onNavigateTab?.call(1);
                                        },
                                        child: Text(slide['btn']!, style: const TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // Indicadores de carrusel
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentSlide == i ? 20 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _currentSlide == i ? AppColors.turquoise : Colors.white54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              // Bienvenida y Propuesta de Valor PlayApp
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.location_on, size: 16, color: AppColors.primary),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'PLAYAPP CARTAGENA • EN LA ORILLA DEL MAR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bienvenido a PlayApp',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tu compañero ideal para disfrutar tus vacaciones en las playas de Cartagena. Pide comida típica, bebidas heladas y servicios en tu carpa o toalla sin moverte de la arena y con precios justos garantizados.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tarjetas de beneficios
                    Row(
                      children: [
                        _buildBenefitCard(
                          icon: Icons.verified_user_outlined,
                          title: 'Sin Estafas',
                          desc: 'Precios justos oficiales',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        _buildBenefitCard(
                          icon: Icons.beach_access_outlined,
                          title: 'En tu Carpa',
                          desc: 'Delivery a la orilla',
                          color: AppColors.turquoise,
                        ),
                        const SizedBox(width: 10),
                        _buildBenefitCard(
                          icon: Icons.payments_outlined,
                          title: 'Wompi & Efectivo',
                          desc: 'Pago seguro o entrega',
                          color: AppColors.coral,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Accesos Rápidos por Categoría
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Categorías Playeras',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        productProv.setCategory(0);
                        widget.onNavigateTab?.call(1);
                      },
                      child: const Text('Ver catálogo', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildCategoryButton(
                      title: 'Comidas',
                      icon: Icons.restaurant,
                      onTap: () {
                        productProv.setCategory(1);
                        widget.onNavigateTab?.call(1);
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildCategoryButton(
                      title: 'Bebidas',
                      icon: Icons.local_bar,
                      onTap: () {
                        productProv.setCategory(2);
                        widget.onNavigateTab?.call(1);
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildCategoryButton(
                      title: 'Servicios',
                      icon: Icons.deck,
                      onTap: () {
                        productProv.setCategory(3);
                        widget.onNavigateTab?.call(1);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Productos Destacados
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Recomendados de la Playa',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        productProv.setCategory(0);
                        widget.onNavigateTab?.call(1);
                      },
                      child: const Text('Ver más', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Consumer<ProductProvider>(
                builder: (context, prov, _) {
                  if (prov.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final featured = prov.allProducts.take(4).toList();
                  if (featured.isEmpty) {
                    return const Center(child: Text('No hay productos disponibles'));
                  }

                  return ResponsiveProductGrid(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    products: featured,
                    onAddToCart: (product, qty) => cartProv.addToCart(product, quantity: qty),
                    onTapProduct: (product) {
                      Navigator.pushNamed(
                        context,
                        '/product-detail',
                        arguments: product,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.sandBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
