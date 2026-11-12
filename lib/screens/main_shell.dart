import 'package:flutter/material.dart';
import '../services/data_gateway.dart';
import '../state/playapp_state.dart';
import '../theme/playapp_theme.dart';
import '../widgets/chat_widget_overlay.dart';
import '../widgets/data_gateway_sheet.dart';
import 'admin_screen.dart';
import 'auth_screen.dart';
import 'cart_screen.dart';
import 'contact_reviews_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'shop_screen.dart';

/// Contenedor principal de navegación de PlayApp móvil con cabecera, tabs y Asistente flotante.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  void _openChat(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PlayAppChatSheet(),
    );
  }

  void _openDataGateway(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DataGatewaySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = PlayAppScope.of(context);
    final isAdmin = state.isAdmin;

    final screens = <Widget>[
      const HomeScreen(),
      const ShopScreen(),
      const OrdersScreen(),
      const ContactReviewsScreen(),
      if (isAdmin) const AdminScreen(),
    ];

    final navDestinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
      const NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront),
        label: 'Tienda',
      ),
      const NavigationDestination(
        icon: Icon(Icons.history),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Pedidos',
      ),
      const NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        selectedIcon: Icon(Icons.chat_bubble),
        label: 'Contacto',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];

    final currentIdx = state.selectedTabIndex.clamp(0, screens.length - 1);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Image.asset('assets/images/Logo.png', height: 26),
            const SizedBox(width: 8),
            const Text(
              'PLAYAPP',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
            if (state.isAuthenticated) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Hola, ${state.currentUser!.nombreCompleto}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: PlayAppColors.accentSky,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pasarela de Datos · MongoDB Atlas',
            onPressed: () => _openDataGateway(context),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.storage_outlined, size: 22),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isDatabaseConnected
                          ? PlayAppColors.successGreen
                          : (state.gatewayStatus == GatewayStatus.conectando
                              ? PlayAppColors.warningAmber
                              : Colors.grey),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              tooltip: 'Carrito de compras',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CartScreen()),
                );
              },
              icon: Badge(
                isLabelVisible: state.carritoBadgeCount > 0,
                backgroundColor: PlayAppColors.dangerRed,
                label: Text('${state.carritoBadgeCount}'),
                child: const Icon(Icons.shopping_bag),
              ),
            ),
          ),
          if (state.isAuthenticated)
            TextButton.icon(
              onPressed: state.logout,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Salir'),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: PlayAppColors.accentSky,
                ),
                icon: const Icon(Icons.person_outline, size: 19),
                label: const Text('Ingresar'),
              ),
            ),
        ],
      ),
      body: IndexedStack(index: currentIdx, children: screens),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Asistente PlayApp',
        backgroundColor: Colors.transparent,
        elevation: 6,
        onPressed: () => _openChat(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/chatbot-button-v2.png',
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIdx,
        onDestinationSelected: (idx) => state.selectTab(idx),
        destinations: navDestinations,
      ),
    );
  }
}
