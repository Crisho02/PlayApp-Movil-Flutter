import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playapp_movil_flutter/data/seed_data.dart';
import 'package:playapp_movil_flutter/main.dart';
import 'package:playapp_movil_flutter/models/pedido.dart';
import 'package:playapp_movil_flutter/models/producto.dart';
import 'package:playapp_movil_flutter/models/usuario.dart';
import 'package:playapp_movil_flutter/state/playapp_state.dart';

void main() {
  testWidgets('Renderiza Home de PlayApp y navega a Tienda', (tester) async {
    await tester.pumpWidget(const PlayAppMobile());
    await tester.pump();

    expect(find.text('PLAYAPP'), findsOneWidget);
    expect(find.text('Bienvenido a PlayApp'), findsOneWidget);

    await tester.tap(find.text('Tienda').last);
    await tester.pumpAndSettle();

    expect(find.text('Arepa de huevo'), findsOneWidget);
    expect(find.text('Arroz de coco'), findsOneWidget);

    await tester.tap(find.text('Bebidas').last);
    await tester.pumpAndSettle();

    expect(find.text('Cerveza nacional'), findsOneWidget);
    expect(find.text('Coco frío'), findsOneWidget);
    expect(
      PlayAppScope.of(tester.element(find.byType(Scaffold).first))
          .shopCategoryFilter,
      CategoriaProducto.bebida,
    );
  });

  testWidgets('Agregar producto al carrito actualiza el contador y valida stock',
      (tester) async {
    final state = PlayAppState();
    final pescado = state.productos.firstWhere(
      (p) => p.nombre == 'Pescado frito',
    );

    expect(state.agregarAlCarrito(pescado, 2), isNull);
    expect(state.carritoBadgeCount, 1);
    expect(state.totalCarrito, 64000);

    final exceso = state.agregarAlCarrito(pescado, pescado.stock);
    expect(exceso, isNotNull);

    await tester.pumpWidget(PlayAppMobile(initialState: state));
    await tester.pump();
    expect(find.text('1'), findsWidgets);
  });

  test('Flujo completo de pedido, pago aprobado y descuento de stock', () {
    final state = PlayAppState();
    final mojarra = state.productos.firstWhere(
      (p) => p.nombre == 'Mojarra con patacones',
    );
    final stockInicial = mojarra.stock;

    state.agregarAlCarrito(mojarra, 2);
    final zona = SeedData.zonasPlaya.first;
    final pedido = state.crearPedidoDesdeCarrito(
      envio: Envio(
        latitud: zona.latitud,
        longitud: zona.longitud,
        direccion: zona.direccion,
        mesaCarpa: 5,
        descripcion: 'Carpa azul',
      ),
      metodoPago: 'Mercado Pago',
    );

    expect(state.carrito, isEmpty);
    expect(pedido.pago.estado, EstadoPago.enEspera);

    final pagado = state.finalizarPago(pedido.id, aprobado: true);
    expect(pagado?.pago.estado, EstadoPago.terminado);

    final mojarraActualizada = state.productos.firstWhere(
      (p) => p.id == mojarra.id,
    );
    expect(mojarraActualizada.stock, stockInicial - 2);
  });

  test('Asistente PlayApp responde precios y bebidas frías del catálogo', () {
    final state = PlayAppState();
    state.enviarMensajeChat('¿Cuánto cuesta el pescado frito?');
    expect(
      state.chatMessages.last.text,
      contains('\$32.000'),
    );

    state.enviarMensajeChat('Recomiéndame bebidas frías');
    expect(
      state.chatMessages.last.text.toLowerCase(),
      contains('limonada de coco'),
    );
  });

  testWidgets('Acceso demo Admin habilita el panel administrativo',
      (tester) async {
    final state = PlayAppState();
    await tester.pumpWidget(PlayAppMobile(initialState: state));
    await tester.pump();

    state.loginDemo(RolUsuario.admin);
    await tester.pumpAndSettle();

    expect(find.text('Admin'), findsOneWidget);
    expect(find.byIcon(Icons.admin_panel_settings), findsOneWidget);
  });
}
