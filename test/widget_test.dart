import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playapp_movil_flutter/core/config/env_config.dart';
import 'package:playapp_movil_flutter/core/constants/app_constants.dart';
import 'package:playapp_movil_flutter/core/utils/currency_formatter.dart';
import 'package:playapp_movil_flutter/data/models/cart_item_model.dart';
import 'package:playapp_movil_flutter/data/models/order_model.dart';
import 'package:playapp_movil_flutter/data/models/product_model.dart';
import 'package:playapp_movil_flutter/data/models/review_model.dart';
import 'package:playapp_movil_flutter/data/models/user_model.dart';
import 'package:playapp_movil_flutter/data/models/admin_weather_model.dart';
import 'package:playapp_movil_flutter/data/models/admin_report_model.dart';
import 'package:playapp_movil_flutter/data/models/admin_user_model.dart';
import 'package:playapp_movil_flutter/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:playapp_movil_flutter/presentation/screens/auth/login_screen.dart';
import 'package:playapp_movil_flutter/presentation/screens/cart/cart_screen.dart';
import 'package:playapp_movil_flutter/presentation/screens/checkout/wompi_card_screen.dart';
import 'package:playapp_movil_flutter/presentation/screens/reviews/reviews_contact_screen.dart';
import 'package:playapp_movil_flutter/presentation/widgets/beach_map_widget.dart';
import 'package:playapp_movil_flutter/presentation/widgets/product_card.dart';
import 'package:playapp_movil_flutter/presentation/widgets/responsive_product_grid.dart';
import 'package:playapp_movil_flutter/presentation/widgets/status_badge.dart';
import 'package:playapp_movil_flutter/providers/admin_provider.dart';
import 'package:playapp_movil_flutter/providers/auth_provider.dart';
import 'package:playapp_movil_flutter/providers/cart_provider.dart';
import 'package:playapp_movil_flutter/providers/order_provider.dart';
import 'package:playapp_movil_flutter/providers/product_provider.dart';
import 'package:playapp_movil_flutter/providers/review_provider.dart';
import 'package:provider/provider.dart';

void main() {
  group('Unit Tests: Currency & Config', () {
    test('CurrencyFormatter formats COP correctly', () {
      final formatted = CurrencyFormatter.formatCOP(25000);
      expect(formatted.contains('25'), isTrue);
      expect(formatted.contains('COP'), isTrue);
    });

    test('EnvConfig has expected defaults and test cards', () {
      expect(EnvConfig.standardDeliveryFee, 5000.0);
      expect(EnvConfig.testCardApproved, '4242424242424242');
      expect(EnvConfig.testCardRejected, '4111111111111111');
      expect(EnvConfig.beachZones.isNotEmpty, isTrue);
    });
  });

  group('Unit Tests: CartProvider Logic', () {
    late CartProvider cart;
    late ProductModel burger;
    late ProductModel mojito;

    setUp(() {
      cart = CartProvider();
      burger = ProductModel(
        id: 'p1',
        nombre: 'Hamburguesa de la casa',
        descripcion: 'Carne artesanal',
        precio: 25000.0,
        cantidadDisponible: 10,
        categoriaId: 1,
        categoriaNombre: 'Comidas',
      );
      mojito = ProductModel(
        id: 'p2',
        nombre: 'Limonada de coco',
        descripcion: 'Bebida fría',
        precio: 14000.0,
        cantidadDisponible: 15,
        categoriaId: 2,
        categoriaNombre: 'Bebidas',
      );
    });

    test('Empty cart has 0 subtotal, 0 shipping, 0 total', () {
      expect(cart.isEmpty, isTrue);
      expect(cart.subtotal, 0.0);
      expect(cart.shippingFee, 0.0);
      expect(cart.total, 0.0);
      expect(cart.itemCount, 0);
    });

    test('Adding products adds shipping fee of \$5.000 COP and computes total', () {
      cart.addToCart(burger, quantity: 2); // 2 * 25000 = 50000
      cart.addToCart(mojito, quantity: 1); // 1 * 14000 = 14000

      expect(cart.itemCount, 3);
      expect(cart.subtotal, 64000.0);
      expect(cart.shippingFee, 5000.0);
      expect(cart.total, 69000.0);
    });

    test('Updating quantity and removing item updates totals', () {
      cart.addToCart(burger, quantity: 2);
      expect(cart.itemCount, 2);

      cart.updateQuantity(burger.id, 1);
      expect(cart.itemCount, 1);
      expect(cart.subtotal, 25000.0);

      cart.removeFromCart(burger.id);
      expect(cart.isEmpty, isTrue);
      expect(cart.total, 0.0);
    });
  });

  group('Unit Tests: Data Models', () {
    test('UserModel parses admin status correctly', () {
      final userJson = {
        'id': 'usr_1',
        'nombre': 'Admin User',
        'email': 'adminplayapp01@gmail.com',
        'roles': ['ROLE_ADMIN'],
        'isAdmin': true,
      };
      final user = UserModel.fromJson(userJson);
      expect(user.isAdmin, isTrue);
      expect(user.email, 'adminplayapp01@gmail.com');
    });

    test('OrderModel parses payment methods and labels', () {
      final order = OrderModel(
        id: 'ord_123',
        fecha: '17-11-2026 12:00',
        total: 30000.0,
        estadoPedido: OrderStatusConstants.recibido,
        estadoPago: PaymentStatusConstants.pendienteContraentrega,
        metodoPago: PaymentMethodConstants.efectivo,
      );

      expect(order.metodoPagoLabel, 'Efectivo contraentrega');
      expect(order.displayCode, '#ord_123');
    });

    test('ProductProvider filters and sorts products', () {
      final prov = ProductProvider();
      prov.setCategory(1); // Comidas
      expect(prov.selectedCategory, 1);

      prov.setSortBy('price_asc');
      expect(prov.sortBy, 'price_asc');
    });

    test('ReviewModel parses MongoDB Atlas response and formats Spanish date', () {
      final json = {
        'id': '67b36f73a5a22830fcfd1933',
        'nombre': 'Walter Espriella',
        'comentario': 'Excelente comida y atención rápida',
        'valoracion': 5,
        'fecha': '2026-05-22T20:44:00.000Z',
      };
      final review = ReviewModel.fromJson(json);
      expect(review.id, '67b36f73a5a22830fcfd1933');
      expect(review.nombreCliente, 'Walter Espriella');
      expect(review.calificacion, 5);
      expect(review.fechaFormateada.contains('mayo'), isTrue);
      expect(review.fechaFormateada.contains('2026'), isTrue);
    });

    test('ReviewModel toJson matches backend POST /api/reviews schema', () {
      final review = ReviewModel(
        id: 'rev_1',
        nombreCliente: 'Catalina Garcia',
        calificacion: 5,
        comentario: 'La mejor experiencia de playa',
        fechaFormateada: 'Hoy',
      );
      final json = review.toJson();
      expect(json['nombre'], 'Catalina Garcia');
      expect(json['valoracion'], 5);
      expect(json['comentario'], 'La mejor experiencia de playa');
    });
  });

  group('Widget Tests: Reusable Components & Responsiveness', () {
    testWidgets('StatusBadge displays label and circle indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              label: 'Pagado',
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Pagado'), findsOneWidget);
    });

    testWidgets('ProductCard displays product details and quantity buttons', (WidgetTester tester) async {
      final product = ProductModel(
        id: 'test_p1',
        nombre: 'Ceviche Mixto',
        descripcion: 'Mariscos frescos',
        precio: 28000.0,
        cantidadDisponible: 12,
        categoriaId: 1,
        categoriaNombre: 'Comidas',
      );

      int addedQty = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 320,
              child: ProductCard(
                product: product,
                onAddToCart: (qty) => addedQty = qty,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Ceviche Mixto'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pump();
      expect(addedQty, 2);
    });

    for (final width in [320.0, 375.0, 390.0, 414.0]) {
      testWidgets('ProductCard renders without RenderFlex overflow at ${width.toInt()}px width', (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final product = ProductModel(
          id: 'test_overflow',
          nombre: 'Hamburguesa de la casa con tocineta',
          descripcion: 'Carne artesanal y papas a la francesa en la playa',
          precio: 25000.0,
          cantidadDisponible: 10,
          categoriaId: 1,
          categoriaNombre: 'Comidas',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.60,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 2,
                itemBuilder: (ctx, i) => ProductCard(
                  product: product,
                  onAddToCart: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Hamburguesa de la casa con tocineta'), findsNWidgets(2));
      });
    }

    for (final width in [320.0, 375.0, 768.0, 1200.0]) {
      testWidgets('ResponsiveProductGrid adapts columns and does not overflow at ${width.toInt()}px width', (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final sampleProducts = [
          ProductModel(
            id: 'p1',
            nombre: 'Arepa de Huevo Tradicional',
            descripcion: 'Deliciosa arepa con huevo de Cartagena',
            precio: 9000.0,
            cantidadDisponible: 20,
            categoriaId: 1,
            categoriaNombre: 'Comidas',
          ),
          ProductModel(
            id: 'p2',
            nombre: 'Arroz de Coco con Pescado',
            descripcion: 'Plato típico costeño frente al mar',
            precio: 35000.0,
            cantidadDisponible: 15,
            categoriaId: 1,
            categoriaNombre: 'Comidas',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveProductGrid(
                products: sampleProducts,
                onAddToCart: (_, __) {},
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Arepa de Huevo Tradicional'), findsOneWidget);
        expect(find.text('Arroz de Coco con Pescado'), findsOneWidget);
      });
    }
  });

  group('Widget Tests: Navigation & Checkout Cleanliness', () {
    testWidgets('Empty cart displays Explorar Tienda button and clean message', (WidgetTester tester) async {
      final cart = CartProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: cart),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      expect(find.text('Tu carrito está vacío'), findsOneWidget);
      expect(find.text('Explorar Tienda'), findsOneWidget);
      expect(find.byIcon(Icons.storefront), findsOneWidget);
    });

    testWidgets('WompiCardScreen displays clean professional UI without sandbox references', (WidgetTester tester) async {
      final orderProv = OrderProvider();
      final cart = CartProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: orderProv),
            ChangeNotifierProvider.value(value: cart),
          ],
          child: const MaterialApp(
            home: WompiCardScreen(
              checkoutData: {
                'total': 45000.0,
                'shipmentData': {
                  'direccion': 'Playa Bocagrande',
                  'barrio': 'Playas de Bocagrande, Cartagena',
                  'carpa': 12,
                },
                'items': [],
                'correo': 'turista@playapp.com',
              },
            ),
          ),
        ),
      );

      // Debe mostrar título profesional
      expect(find.text('Pagar con Tarjeta'), findsOneWidget);
      expect(find.text('Datos de la Tarjeta'), findsOneWidget);
      expect(find.text('Total a Pagar:'), findsOneWidget);

      // NO debe contener palabras técnicas de entorno ni números prellenados de prueba
      expect(find.textContaining('Sandbox'), findsNothing);
      expect(find.textContaining('Tarjetas de prueba'), findsNothing);
      expect(find.textContaining('Aprobada (4242)'), findsNothing);
      expect(find.textContaining('Rechazada (4111)'), findsNothing);
      expect(find.text('4242424242424242'), findsNothing);
    });

    testWidgets('BeachMapWidget renders Bocagrande beach sectors and interactive map controls', (WidgetTester tester) async {
      final carpaCtrl = TextEditingController();
      final notesCtrl = TextEditingController();
      final addressCtrl = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BeachMapWidget(
                selectedZone: 'Playas de Bocagrande, Cartagena',
                onZoneChanged: (_) {},
                carpaController: carpaCtrl,
                notesController: notesCtrl,
                addressController: addressCtrl,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Zona de Entrega en Playa'), findsOneWidget);
      expect(find.text('Playas de Bocagrande, Cartagena'), findsOneWidget);
      expect(find.text('Bocagrande Central (Hotel Caribe)'), findsOneWidget);
      expect(find.text('N° Carpa / Mesa'), findsOneWidget);
      expect(find.text('Referencia / Toalla'), findsOneWidget);
    });

    test('AdminWeatherModel parses weather without raw string dumps', () {
      final json = {
        'description': 'cielo claro',
        'observedAt': '17/11/2026 18:14:06',
        'consultedAt': '17/11/2026 18:19:52',
        'metrics': [
          {'label': 'Temperatura', 'value': '30,0 °C'},
          {'label': 'Sensación térmica', 'value': '36,1 °C'},
          {'label': 'Viento', 'value': '17,7 km/h'},
          {'label': 'Humedad', 'value': '74,0 %'},
          {'label': 'Nubosidad', 'value': '0,0 %'},
          {'label': 'Presión atmosférica', 'value': '1007,0 hPa'},
          {'label': 'Visibilidad', 'value': '10,0 km'},
          {'label': 'Amanecer', 'value': '17/11/2026 05:58:15'},
          {'label': 'Atardecer', 'value': '17/11/2026 17:36:24'},
        ],
        'estimate': {
          'minimum': 0,
          'maximum': 1,
          'condition': 'Noche',
          'explanation': 'En Bocagrande se registran 30,0 °C.',
          'summary': 'Durante la noche se espera una afluencia muy baja.',
        },
        'artwork': {'key': 'night', 'night': true},
      };

      final weather = AdminWeatherModel.fromJson(json);

      expect(weather.description, 'cielo claro');
      expect(weather.temperature, '30,0 °C');
      expect(weather.feelsLike, '36,1 °C');
      expect(weather.wind, '17,7 km/h');
      expect(weather.humidity, '74,0 %');
      expect(weather.clouds, '0,0 %');
      expect(weather.pressure, '1007,0 hPa');
      expect(weather.visibility, '10,0 km');
      expect(weather.sunrise, '05:58:15');
      expect(weather.sunset, '17:36:24');
      expect(weather.isNight, isTrue);

      expect(weather.estimate, isNotNull);
      expect(weather.estimate!.minimum, 0);
      expect(weather.estimate!.maximum, 1);
      expect(weather.estimate!.condition, 'Noche');

      // Verificar que NO se produzcan volcados de mapas como texto
      expect(weather.temperature.contains('{label:'), isFalse);
      expect(weather.description.contains('{minimum:'), isFalse);
    });

    test('AdminReportModel parses executive metrics and top products', () {
      final json = {
        'pedidos': {
          'totalPedidos': 130,
          'ingresosTotales': 28224000.0,
          'promedioProductosPorPedido': 13.2,
          'ingresosMensuales': [
            {'anio': 2026, 'mes': 11, 'periodo': '2026-11', 'pedidos': 17, 'ingresos': 523000.0},
          ],
        },
        'productosTop': [
          {'id': 'p1', 'nombre': 'Cerveza Club Colombia', 'precio': 8000.0, 'cantidadVendida': 140, 'ingresosGenerados': 1120000.0},
          {'id': 'p2', 'nombre': 'Ceviche de camarón', 'precio': 28000.0, 'cantidadVendida': 85, 'ingresosGenerados': 2380000.0},
        ],
      };

      final report = AdminReportModel.fromJson(json);

      expect(report.totalPedidos, 130);
      expect(report.ingresosTotales, 28224000.0);
      expect(report.promedioProductosPorPedido, 13.2);
      expect(report.ingresosMensuales.length, 1);
      expect(report.ingresosMensuales.first.periodo, '2026-11');
      expect(report.productosTop.length, 2);
      expect(report.productosTop.first.nombre, 'Cerveza Club Colombia');
      expect(report.productosTop.first.cantidadVendida, 140);
    });

    test('AdminUserModel parses users and detects admin rights', () {
      final jsonUser = {
        'id': 'u1',
        'nombre': 'Cristian Tapias',
        'correo': 'sear0231@gmail.com',
        'rol': 'ROLE_USER',
        'esAdmin': false,
      };

      final jsonAdmin = {
        'id': 'a1',
        'nombre': 'Administrador PlayApp',
        'correo': 'adminplayapp01@gmail.com',
        'rol': 'ROLE_ADMIN',
        'esAdmin': true,
      };

      final user = AdminUserModel.fromJson(jsonUser);
      final admin = AdminUserModel.fromJson(jsonAdmin);

      expect(user.esAdmin, isFalse);
      expect(user.rol, 'ROLE_USER');
      expect(admin.esAdmin, isTrue);
      expect(admin.rol, 'ROLE_ADMIN');
    });

    testWidgets('AdminDashboardScreen blocks non-admin users with access denied view', (WidgetTester tester) async {
      final auth = AuthProvider();
      final adminProv = AdminProvider();
      final prodProv = ProductProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: adminProv),
            ChangeNotifierProvider.value(value: prodProv),
          ],
          child: const MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );

      // Dado que auth no tiene usuario administrador, debe mostrar acceso denegado
      expect(find.text('Acceso No Autorizado'), findsOneWidget);
      expect(find.text('Acceso Restringido'), findsOneWidget);
      expect(find.text('Volver a la Tienda'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('LoginScreen has no prefilled admin credentials or testing buttons', (WidgetTester tester) async {
      final auth = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // No debe existir el botón de prueba de administrador
      expect(find.text('Llenar credenciales Administrador'), findsNothing);
      expect(find.byIcon(Icons.admin_panel_settings_outlined), findsNothing);

      // Los campos deben iniciar limpios sin secretos ni correos pre-cargados
      final emailField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
      );
      expect(emailField.controller?.text.isEmpty, isTrue);

      final passField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Contraseña'),
      );
      expect(passField.controller?.text.isEmpty, isTrue);
    });

    testWidgets('ReviewsContactScreen renders without overflow at 320px mobile width', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final auth = AuthProvider();
      final reviewProv = ReviewProvider();
      final cartProv = CartProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: reviewProv),
            ChangeNotifierProvider.value(value: cartProv),
          ],
          child: const MaterialApp(
            home: ReviewsContactScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Reseñas de PlayApp'), findsOneWidget);
      expect(find.text('Valoración:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('EnvConfig resolves candidates and defaults cleanly', () {
      expect(EnvConfig.apiBaseUrl.startsWith('http://'), isTrue);
      EnvConfig.setActiveBaseUrl('http://127.0.0.1:8080');
      expect(EnvConfig.apiBaseUrl, 'http://127.0.0.1:8080');
    });

    test('AdminTopProduct parses historical unit price, revenue and calculates rank', () {
      final jsonSample = {
        'nombre': 'Pescado frito',
        'cantidad': 194,
        'ingresos': 6208000.0,
        'precioUnitario': 32000.0,
      };
      final top = AdminTopProduct.fromJson(jsonSample);
      expect(top.nombre, 'Pescado frito');
      expect(top.cantidadVendida, 194);
      expect(top.precio, 32000.0);
      expect(top.ingresosGenerados, 6208000.0);
      expect(CurrencyFormatter.formatCOP(top.precio), contains('32.000'));
      expect(CurrencyFormatter.formatCOP(top.ingresosGenerados), contains('6.208.000'));
    });

    test('AdminTopProduct calculates unit price from revenue if price is missing or zero', () {
      final jsonFallback = {
        'nombre': 'Mojarra con patacones',
        'cantidad': 100,
        'ingresos': 3500000.0,
      };
      final top = AdminTopProduct.fromJson(jsonFallback);
      expect(top.cantidadVendida, 100);
      expect(top.precio, 35000.0);
      expect(top.ingresosGenerados, 3500000.0);
    });

    test('CartItemModel unpacks nested mongo producto object with image and pricing', () {
      final jsonWithNestedProduct = {
        'cantidad': 2,
        'producto': {
          'id': '6738c8230b80f252cfdf7ecb',
          'nombre': 'Arepa de huevo',
          'precio': 9000.0,
          'imageSRC': 'data:image/jpeg;base64,/9j/4AAQSkZJRg...',
        },
      };
      final item = CartItemModel.fromJson(jsonWithNestedProduct);
      expect(item.id, '6738c8230b80f252cfdf7ecb');
      expect(item.nombre, 'Arepa de huevo');
      expect(item.precio, 9000.0);
      expect(item.cantidad, 2);
      expect(item.subtotal, 18000.0);
      expect(item.imageSrc, contains('data:image/jpeg;base64'));
    });

    test('ProductModel.inferAssetFallback recognizes food and drink items correctly', () {
      expect(ProductModel.inferAssetFallback('Coca-Cola 400ml'), 'assets/images/Bebidas.jpeg');
      expect(ProductModel.inferAssetFallback('Cerveza Club Colombia'), 'assets/images/Bebidas.jpeg');
      expect(ProductModel.inferAssetFallback('Pescado frito con arroz'), 'assets/images/Pescado.jpg');
      expect(ProductModel.inferAssetFallback('Arepa de huevo costeña'), 'assets/images/catalogo/arepa-huevo.jpg');
      expect(ProductModel.inferAssetFallback('Arroz de coco tradicional'), 'assets/images/catalogo/arroz-coco.jpg');
    });
  });
}
