import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playapp_movil_flutter/data/seed_data.dart';
import 'package:playapp_movil_flutter/main.dart';
import 'package:playapp_movil_flutter/models/pedido.dart';
import 'package:playapp_movil_flutter/models/producto.dart';
import 'package:playapp_movil_flutter/models/resena.dart';
import 'package:playapp_movil_flutter/models/usuario.dart';
import 'package:playapp_movil_flutter/services/data_gateway.dart';
import 'package:playapp_movil_flutter/state/playapp_state.dart';

void main() {
  testWidgets('Renderiza Home de PlayApp y navega a Tienda', (tester) async {
    final state = PlayAppState(autoConnectDatabase: false);
    await tester.pumpWidget(PlayAppMobile(initialState: state));
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
    final state = PlayAppState(autoConnectDatabase: false);
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
    final state = PlayAppState(autoConnectDatabase: false);
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
    final state = PlayAppState(autoConnectDatabase: false);
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
    final state = PlayAppState(autoConnectDatabase: false);
    await tester.pumpWidget(PlayAppMobile(initialState: state));
    await tester.pump();

    state.loginDemo(RolUsuario.admin);
    await tester.pumpAndSettle();

    expect(find.text('Admin'), findsOneWidget);
    expect(find.byIcon(Icons.admin_panel_settings), findsOneWidget);
  });

  test('Mapeo bidireccional de MongoDB para productos, usuarios y pedidos', () {
    final mongoProdDoc = {
      '_id': '6a0697b3fe828b741c8bdf04',
      'nombre': 'Ceviche de camarón',
      'descripcion': 'Fresco frente al mar',
      'precio': 28000.0,
      'stock': 15.0,
      'categoria': 1,
      'tipo': 4,
      'entidad': {
        '_id': '6a0697b2fe828b741c8bdf03',
        'nombreCompleto': 'Kiosco El Bony',
      },
    };

    final prod = Producto.fromMongo(mongoProdDoc);
    expect(prod.id, '6a0697b3fe828b741c8bdf04');
    expect(prod.nombre, 'Ceviche de camarón');
    expect(prod.categoria, CategoriaProducto.comida);
    expect(prod.entidadNombre, 'Kiosco El Bony');

    final backDoc = prod.toMongo();
    expect(backDoc['nombre'], 'Ceviche de camarón');
    expect(backDoc['_class'], 'com.proyecto.PlayApp.entity.Producto');

    final userDoc = {
      '_id': '6a0697b2fe828b741c8bdf03',
      'nombreCompleto': 'Administrador PlayApp',
      'correo': 'adminplayapp01@gmail.com',
      'password': 'hash',
      'rol': 'ROLE_ADMIN',
    };
    final user = Usuario.fromMongo(userDoc);
    expect(user.rol, RolUsuario.admin);
    expect(user.correo, 'adminplayapp01@gmail.com');

    final resenaDoc = {
      '_id': 'rev-1',
      'nombre': 'Carlos Pérez',
      'valoracion': 5,
      'comentario': 'Excelente comida y rápida entrega en carpa',
      'fecha': DateTime.now(),
    };
    final resena = Resena.fromMongo(resenaDoc);
    expect(resena.valoracion, 5);
    expect(resena.nombre, 'Carlos Pérez');
  });

  test('Pasarela de Datos status inicial y fallback seguro', () {
    final gateway = PlayAppDataGateway();
    expect(gateway.status, GatewayStatus.desconectado);
    expect(gateway.databaseName, 'playappdb');
  });
}
