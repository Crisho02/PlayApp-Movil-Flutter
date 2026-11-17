import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/storage/session_manager.dart';
import 'core/theme/app_theme.dart';
import 'data/models/order_model.dart';
import 'data/models/product_model.dart';
import 'presentation/screens/admin/admin_dashboard_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/cart/cart_screen.dart';
import 'presentation/screens/checkout/payment_method_screen.dart';
import 'presentation/screens/checkout/shipment_screen.dart';
import 'presentation/screens/checkout/wompi_card_screen.dart';
import 'presentation/screens/main/main_shell.dart';
import 'presentation/screens/orders/order_confirmation_screen.dart';
import 'presentation/screens/shop/product_detail_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
import 'providers/review_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager.init();
  runApp(const PlayAppMovil());
}

class PlayAppMovil extends StatelessWidget {
  const PlayAppMovil({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'PlayApp Cartagena',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/main': (context) => const MainShell(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/cart': (context) => const CartScreen(),
          '/checkout-shipment': (context) => const ShipmentScreen(),
          '/orders': (context) => const MainShell(initialTab: 2),
          '/admin': (context) => const AdminDashboardScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/product-detail') {
            final product = settings.arguments as ProductModel;
            return MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            );
          }
          if (settings.name == '/checkout-payment') {
            final shipmentData = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => PaymentMethodScreen(shipmentData: shipmentData),
            );
          }
          if (settings.name == '/checkout-wompi-card') {
            final checkoutData = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => WompiCardScreen(checkoutData: checkoutData),
            );
          }
          if (settings.name == '/order-confirmation') {
            final order = settings.arguments as OrderModel;
            return MaterialPageRoute(
              builder: (context) => OrderConfirmationScreen(order: order),
            );
          }
          return null;
        },
      ),
    );
  }
}
