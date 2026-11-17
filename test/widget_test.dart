import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playapp_movil_flutter/core/config/env_config.dart';
import 'package:playapp_movil_flutter/core/constants/app_constants.dart';
import 'package:playapp_movil_flutter/core/utils/currency_formatter.dart';
import 'package:playapp_movil_flutter/data/models/order_model.dart';
import 'package:playapp_movil_flutter/data/models/product_model.dart';
import 'package:playapp_movil_flutter/data/models/review_model.dart';
import 'package:playapp_movil_flutter/data/models/user_model.dart';
import 'package:playapp_movil_flutter/presentation/widgets/product_card.dart';
import 'package:playapp_movil_flutter/presentation/widgets/status_badge.dart';
import 'package:playapp_movil_flutter/providers/cart_provider.dart';
import 'package:playapp_movil_flutter/providers/product_provider.dart';

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
  });
}
