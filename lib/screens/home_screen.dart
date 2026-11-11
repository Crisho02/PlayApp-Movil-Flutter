import 'dart:async';
import 'package:flutter/material.dart';
import '../data/seed_data.dart';
import '../models/producto.dart';
import '../state/playapp_state.dart';
import '../theme/playapp_theme.dart';

/// Pantalla de inicio (`index.html`): carrusel, bienvenida, categorías populares y ubicación.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pageController = PageController();
  int _currentSlide = 0;
  Timer? _autoSlideTimer;

  static const _slides = [
    (
      asset: 'assets/images/Burguer.jpg',
      title: 'Hamburguesa de la casa',
      subtitle: 'Sabores frente al mar con precios transparentes',
    ),
    (
      asset: 'assets/images/Pescado.jpg',
      title: 'Mojarra',
      subtitle: 'Pescado fresco, patacones y arroz de coco en tu carpa',
    ),
    (
      asset: 'assets/images/Bebidas.jpeg',
      title: 'Bebidas',
      subtitle: 'Limonada de coco, jugos naturales y bebidas bien frías',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentSlide + 1) % _slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = PlayAppScope.of(context);

    return ColoredBox(
      color: PlayAppColors.darkSurface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeroCarousel(),
          _buildWelcomeSection(state),
          _buildCoastalCategoriesAndLocation(state),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeroCarousel() {
    return SizedBox(
      height: 290,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (idx) => setState(() => _currentSlide = idx),
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(slide.asset, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x33000000),
                          Color(0x77000000),
                          Color(0xE60E121A),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 40,
                    child: Column(
                      children: [
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black87),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _currentSlide;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? PlayAppColors.accentSky : Colors.white54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(PlayAppState state) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
      child: Column(
        children: [
          const Text(
            'Bienvenido a PlayApp',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'PlayApp es tu compañero ideal para disfrutar de tus vacaciones en las playas de Cartagena y en toda Colombia. '
            'Con nuestra plataforma, puedes realizar compras de comida en los mejores establecimientos, '
            'reservar carpas para tu comodidad y evitar estafas gracias a nuestras recomendaciones y alertas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: PlayAppColors.primaryBlue.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PlayAppColors.accentSky.withValues(alpha: 0.45),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user, color: PlayAppColors.accentSky),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Precios oficiales verificados en playa · Evita sobrecostos',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => state.selectTab(1),
              icon: const Icon(Icons.storefront),
              label: const Text('Explorar Tienda PlayApp'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoastalCategoriesAndLocation(PlayAppState state) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/costa-de-isla-vista-aerea.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Colors.black.withValues(alpha: 0.56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        child: Column(
          children: [
            const Text(
              'Categorías Populares',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _CategoryTile(
                    title: 'Comida',
                    asset: 'assets/images/Langosta.png',
                    onTap: () => state.selectTab(
                      1,
                      categoryFilter: CategoriaProducto.comida,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CategoryTile(
                    title: 'Bebidas',
                    asset: 'assets/images/Bebida.png',
                    onTap: () => state.selectTab(
                      1,
                      categoryFilter: CategoriaProducto.bebida,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CategoryTile(
                    title: 'Servicios',
                    asset: 'assets/images/Moto.png',
                    onTap: () => state.selectTab(
                      1,
                      categoryFilter: CategoriaProducto.servicio,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Ubicación',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Visítanos o recibe tu pedido directo en tu carpa:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 14),
            _buildCoverageCard(state),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverageCard(PlayAppState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PlayAppColors.darkCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: PlayAppColors.accentSky),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Playa de Bocagrande · Cartagena de Indias',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SeedData.zonasPlaya.map((zona) {
              return Chip(
                avatar: const Icon(
                  Icons.beach_access,
                  size: 16,
                  color: PlayAppColors.primaryBlue,
                ),
                label: Text(
                  zona.nombre,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                backgroundColor: Colors.white,
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sede principal: Cra. 1, Cartagena de Indias, Bolívar - Kiosco El Bony',
            style: TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => state.selectTab(3),
              style: TextButton.styleFrom(
                foregroundColor: PlayAppColors.accentSky,
              ),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Ver reseñas y contacto'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: const Column(
        children: [
          Text(
            '© 2026 PlayApp. Todos los derechos reservados.',
            style: TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          SizedBox(height: 4),
          Text(
            'Cartagena de Indias, Colombia · Versión Móvil Flutter',
            style: TextStyle(color: Colors.white38, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.asset,
    required this.onTap,
  });

  final String title;
  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset(asset, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
