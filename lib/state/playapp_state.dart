import 'package:flutter/material.dart';
import '../data/seed_data.dart';
import '../models/carrito_item.dart';
import '../models/chat_message.dart';
import '../models/pedido.dart';
import '../models/producto.dart';
import '../models/resena.dart';
import '../models/usuario.dart';
import '../services/chat_bot_service.dart';

/// Opciones de ordenamiento disponibles en la tienda de PlayApp.
enum OrdenTienda {
  nombreAsc('Nombre (A-Z)'),
  precioDesc('Mayor Precio'),
  precioAsc('Menor Precio');

  const OrdenTienda(this.etiqueta);
  final String etiqueta;
}

/// Estado global reactivo de PlayApp (autenticación, tienda, carrito, pedidos, reseñas y chat).
class PlayAppState extends ChangeNotifier {
  PlayAppState() {
    _usuarios.addAll(SeedData.initialUsuarios());
    _productos.addAll(SeedData.initialProductos());
    _resenas.addAll(SeedData.initialResenas());
    _pedidos.addAll(SeedData.initialPedidos());
    _chatMessages.add(
      ChatMessage(
        id: 'chat-welcome',
        sender: ChatSender.assistant,
        text:
            '¡Hola! Soy el Asistente PlayApp. Pregúntame por precios oficiales en Cartagena, bebidas frías o el estado de tus pedidos.',
        timestamp: DateTime.now(),
      ),
    );
  }

  final List<Usuario> _usuarios = [];
  final List<Producto> _productos = [];
  final List<CarritoItem> _carrito = [];
  final List<Pedido> _pedidos = [];
  final List<Resena> _resenas = [];
  final List<MensajeContacto> _mensajes = [];
  final List<ChatMessage> _chatMessages = [];

  Usuario? _currentUser;
  int _selectedTabIndex = 0;
  CategoriaProducto? _shopCategoryFilter;

  Usuario? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.rol == RolUsuario.admin;

  int get selectedTabIndex => _selectedTabIndex;
  CategoriaProducto? get shopCategoryFilter => _shopCategoryFilter;

  List<Producto> get productos => List.unmodifiable(_productos);
  List<CarritoItem> get carrito => List.unmodifiable(_carrito);
  List<Pedido> get pedidos => List.unmodifiable(_pedidos);
  List<Resena> get resenas => List.unmodifiable(_resenas);
  List<MensajeContacto> get mensajes => List.unmodifiable(_mensajes);
  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);

  int get carritoBadgeCount => _carrito.length;

  int get totalUnidadesCarrito =>
      _carrito.fold(0, (sum, item) => sum + item.cantidad);

  double get totalCarrito =>
      _carrito.fold(0, (sum, item) => sum + item.subtotal);

  /// Navega entre pestañas principales de forma centralizada.
  void selectTab(int index, {CategoriaProducto? categoryFilter}) {
    _selectedTabIndex = index;
    if (categoryFilter != null) {
      _shopCategoryFilter = categoryFilter;
    }
    notifyListeners();
  }

  void setShopCategoryFilter(CategoriaProducto? category) {
    _shopCategoryFilter = category;
    notifyListeners();
  }

  /// Filtra y ordena el catálogo según texto, categoría y criterio elegido.
  List<Producto> filtrarProductos({
    String query = '',
    CategoriaProducto? categoria,
    OrdenTienda orden = OrdenTienda.nombreAsc,
  }) {
    final normQuery = query.trim().toLowerCase();
    final filtered = _productos.where((p) {
      final matchesCat = categoria == null || p.categoria == categoria;
      final matchesQuery = normQuery.isEmpty ||
          p.nombre.toLowerCase().contains(normQuery) ||
          p.descripcion.toLowerCase().contains(normQuery) ||
          p.entidadNombre.toLowerCase().contains(normQuery);
      return matchesCat && matchesQuery;
    }).toList();

    switch (orden) {
      case OrdenTienda.nombreAsc:
        filtered.sort((a, b) => a.nombre.compareTo(b.nombre));
      case OrdenTienda.precioDesc:
        filtered.sort((a, b) => b.precio.compareTo(a.precio));
      case OrdenTienda.precioAsc:
        filtered.sort((a, b) => a.precio.compareTo(b.precio));
    }
    return filtered;
  }

  /// Autentica validando correo, contraseña y rol esperado (igual que Spring Security en PlayApp).
  String? login({
    required String correo,
    required String password,
    required RolUsuario rolEsperado,
  }) {
    final normalizedEmail = correo.trim().toLowerCase();
    final match = _usuarios.where(
      (u) => u.correo.toLowerCase() == normalizedEmail,
    );
    if (match.isEmpty) {
      return 'Correo o contraseña incorrectos. Inténtalo de nuevo.';
    }
    final user = match.first;
    if (user.password != password) {
      return 'Correo o contraseña incorrectos. Inténtalo de nuevo.';
    }
    if (user.rol != rolEsperado) {
      return 'El rol seleccionado no coincide con esta cuenta. Intenta de nuevo con el rol correcto.';
    }
    _currentUser = user;
    notifyListeners();
    return null;
  }

  /// Acceso rápido con credenciales demo precargadas.
  void loginDemo(RolUsuario rol) {
    final demo = _usuarios.firstWhere((u) => u.rol == rol);
    _currentUser = demo;
    _selectedTabIndex = rol == RolUsuario.admin ? 4 : 0;
    notifyListeners();
  }

  /// Registra una nueva cuenta de Usuario o Administrador en memoria.
  String? register({
    required String nombreCompleto,
    required String correo,
    required String password,
    required RolUsuario rol,
  }) {
    final normalizedEmail = correo.trim().toLowerCase();
    if (nombreCompleto.trim().isEmpty ||
        normalizedEmail.isEmpty ||
        password.length < 4) {
      return 'Completa todos los campos (contraseña mínimo 4 caracteres).';
    }
    final exists = _usuarios.any(
      (u) => u.correo.toLowerCase() == normalizedEmail,
    );
    if (exists) {
      return 'Ya existe una cuenta registrada con ese correo.';
    }
    final nuevo = Usuario(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      nombreCompleto: nombreCompleto.trim(),
      correo: normalizedEmail,
      password: password,
      rol: rol,
    );
    _usuarios.add(nuevo);
    _currentUser = nuevo;
    notifyListeners();
    return null;
  }

  void logout() {
    _currentUser = null;
    if (_selectedTabIndex >= 4) {
      _selectedTabIndex = 0;
    }
    notifyListeners();
  }

  /// Agrega al carrito verificando existencias disponibles.
  String? agregarAlCarrito(Producto producto, int cantidad) {
    if (cantidad <= 0) {
      return 'La cantidad debe ser mayor a cero.';
    }
    final idx = _carrito.indexWhere((i) => i.producto.id == producto.id);
    final cantidadActual = idx >= 0 ? _carrito[idx].cantidad : 0;
    if (cantidadActual + cantidad > producto.stock) {
      return 'El producto "${producto.nombre}" no cuenta con suficientes existencias (${producto.stock} disp.).';
    }
    if (idx >= 0) {
      _carrito[idx] = _carrito[idx].copyWith(
        cantidad: cantidadActual + cantidad,
      );
    } else {
      _carrito.add(CarritoItem(producto: producto, cantidad: cantidad));
    }
    notifyListeners();
    return null;
  }

  void actualizarCantidadCarrito(String productoId, int nuevaCantidad) {
    final idx = _carrito.indexWhere((i) => i.producto.id == productoId);
    if (idx < 0) return;
    final item = _carrito[idx];
    if (nuevaCantidad <= 0) {
      _carrito.removeAt(idx);
    } else if (nuevaCantidad <= item.producto.stock) {
      _carrito[idx] = item.copyWith(cantidad: nuevaCantidad);
    }
    notifyListeners();
  }

  void eliminarDelCarrito(String productoId) {
    _carrito.removeWhere((item) => item.producto.id == productoId);
    notifyListeners();
  }

  /// Crea un pedido en estado `Recibido` con pago `En espera` antes de ir a la pasarela.
  Pedido crearPedidoDesdeCarrito({
    required Envio envio,
    required String metodoPago,
  }) {
    final now = DateTime.now();
    final itemsPedido = _carrito
        .map(
          (item) => PedidoItem(
            productoId: item.producto.id,
            nombre: item.producto.nombre,
            precioUnitario: item.producto.precio,
            cantidad: item.cantidad,
            entidadNombre: item.producto.entidadNombre,
          ),
        )
        .toList();

    final total = totalCarrito;
    final shortHex =
        now.millisecondsSinceEpoch.toRadixString(16).toUpperCase();
    final id = 'PA${shortHex.substring(shortHex.length - 6)}';

    final pedido = Pedido(
      id: id,
      clienteCorreo: _currentUser?.correo ?? 'invitado@playapp.co',
      clienteNombre: _currentUser?.nombreCompleto ?? 'Visitante PlayApp',
      estado: EstadoPedido.recibido,
      total: total,
      timestamp: now,
      items: itemsPedido,
      pago: Pago(
        metodo: metodoPago,
        valor: total,
        estado: EstadoPago.enEspera,
        fecha: now,
      ),
      envio: envio,
    );

    _pedidos.insert(0, pedido);
    _carrito.clear();
    notifyListeners();
    return pedido;
  }

  /// Procesa la confirmación o cancelación del pago en la pasarela.
  Pedido? finalizarPago(String pedidoId, {required bool aprobado}) {
    final idx = _pedidos.indexWhere((p) => p.id == pedidoId);
    if (idx < 0) return null;

    final pedido = _pedidos[idx];
    final nuevoEstadoPago =
        aprobado ? EstadoPago.terminado : EstadoPago.cancelado;

    if (aprobado && pedido.pago.estado != EstadoPago.terminado) {
      _descontarStockPedido(pedido);
    }

    final actualizado = pedido.copyWith(
      pago: pedido.pago.copyWith(
        estado: nuevoEstadoPago,
        fecha: DateTime.now(),
      ),
    );
    _pedidos[idx] = actualizado;
    notifyListeners();
    return actualizado;
  }

  void _descontarStockPedido(Pedido pedido) {
    for (final item in pedido.items) {
      final pIdx = _productos.indexWhere((p) => p.id == item.productoId);
      if (pIdx >= 0) {
        final actual = _productos[pIdx];
        final nuevoStock = (actual.stock - item.cantidad).clamp(0, 9999);
        _productos[pIdx] = actual.copyWith(stock: nuevoStock);
      }
    }
  }

  List<Pedido> pedidosDelCliente({EstadoPedido? estado}) {
    final correo = _currentUser?.correo;
    return _pedidos.where((p) {
      final matchesUser =
          correo == null || p.clienteCorreo == correo || isAdmin;
      final matchesState = estado == null || p.estado == estado;
      return matchesUser && matchesState;
    }).toList();
  }

  // --- Funciones de Administración (Management) ---

  void actualizarEstadoPedido(String pedidoId, EstadoPedido nuevoEstado) {
    final idx = _pedidos.indexWhere((p) => p.id == pedidoId);
    if (idx < 0) return;
    _pedidos[idx] = _pedidos[idx].copyWith(estado: nuevoEstado);
    notifyListeners();
  }

  void guardarProducto({
    String? id,
    required String nombre,
    required String descripcion,
    required double precio,
    required int stock,
    required CategoriaProducto categoria,
  }) {
    if (id != null) {
      final idx = _productos.indexWhere((p) => p.id == id);
      if (idx >= 0) {
        _productos[idx] = _productos[idx].copyWith(
          nombre: nombre,
          descripcion: descripcion,
          precio: precio,
          stock: stock,
          categoria: categoria,
        );
        notifyListeners();
        return;
      }
    }

    final defaultAsset = switch (categoria) {
      CategoriaProducto.comida => 'assets/images/catalogo/pescado-frito.jpg',
      CategoriaProducto.bebida => 'assets/images/catalogo/limonada-coco.jpg',
      CategoriaProducto.servicio => 'assets/images/ArenaDemas.jpg',
    };

    _productos.insert(
      0,
      Producto(
        id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
        nombre: nombre,
        descripcion: descripcion,
        precio: precio,
        stock: stock,
        categoria: categoria,
        imagenAsset: defaultAsset,
        entidadNombre: _currentUser?.nombreCompleto ?? 'PlayApp Admin',
      ),
    );
    notifyListeners();
  }

  void eliminarProducto(String id) {
    _productos.removeWhere((p) => p.id == id);
    _carrito.removeWhere((item) => item.producto.id == id);
    notifyListeners();
  }

  double get ingresosTotales => _pedidos
      .where((p) => p.pago.estado != EstadoPago.cancelado)
      .fold(0.0, (sum, p) => sum + p.total);

  double get valorInventario =>
      _productos.fold(0.0, (sum, p) => sum + (p.precio * p.stock));

  double get calificacionPromedio {
    if (_resenas.isEmpty) return 0.0;
    final total = _resenas.fold<int>(0, (sum, r) => sum + r.valoracion);
    return total / _resenas.length;
  }

  /// Simulador local de predicción de ventas inspirado en `WekaPredictionService`.
  double predecirVenta({
    required String diaSemana,
    required CategoriaProducto categoria,
    required double precio,
    required String clima,
    required String temporada,
  }) {
    var base = switch (categoria) {
      CategoriaProducto.bebida => 32.0,
      CategoriaProducto.comida => 22.0,
      CategoriaProducto.servicio => 11.0,
    };
    if (diaSemana == 'Sabado' || diaSemana == 'Domingo') {
      base *= 1.45;
    } else if (diaSemana == 'Viernes') {
      base *= 1.25;
    }
    if (clima == 'Soleado') {
      base *= categoria == CategoriaProducto.bebida ? 1.35 : 1.18;
    } else if (clima == 'Lluvioso') {
      base *= 0.65;
    }
    if (temporada == 'Alta') {
      base *= 1.4;
    } else if (temporada == 'Baja') {
      base *= 0.78;
    }
    if (precio > 40000) {
      base *= 0.85;
    }
    return double.parse(base.toStringAsFixed(2));
  }

  // --- Reseñas, Contacto y Chat ---

  void agregarResena({
    required String nombre,
    required int valoracion,
    required String comentario,
  }) {
    _resenas.insert(
      0,
      Resena(
        id: 'rev-${DateTime.now().millisecondsSinceEpoch}',
        nombre: nombre.trim(),
        valoracion: valoracion.clamp(1, 5),
        comentario: comentario.trim(),
        fecha: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void enviarMensajeContacto({
    required String nombre,
    required String email,
    required String asunto,
    required String mensaje,
  }) {
    _mensajes.insert(
      0,
      MensajeContacto(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        nombre: nombre.trim(),
        email: email.trim(),
        asunto: asunto,
        mensaje: mensaje.trim(),
        fecha: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void enviarMensajeChat(String texto) {
    final trimmed = texto.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();
    _chatMessages.add(
      ChatMessage(
        id: 'u-${now.millisecondsSinceEpoch}',
        sender: ChatSender.user,
        text: trimmed,
        timestamp: now,
      ),
    );

    final respuesta = ChatBotService.responder(
      mensaje: trimmed,
      productos: _productos,
      pedidos: _pedidos,
      itemsEnCarrito: carritoBadgeCount,
      usuarioNombre: _currentUser?.nombreCompleto,
    );

    _chatMessages.add(
      ChatMessage(
        id: 'a-${now.millisecondsSinceEpoch + 1}',
        sender: ChatSender.assistant,
        text: respuesta,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}

/// Provee [PlayAppState] en el árbol de widgets sin dependencias externas.
class PlayAppScope extends InheritedNotifier<PlayAppState> {
  const PlayAppScope({
    super.key,
    required PlayAppState state,
    required super.child,
  }) : super(notifier: state);

  static PlayAppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PlayAppScope>();
    assert(scope != null, 'PlayAppScope no encontrado en el árbol de widgets');
    return scope!.notifier!;
  }
}
