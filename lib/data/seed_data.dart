import '../models/pedido.dart';
import '../models/producto.dart';
import '../models/resena.dart';
import '../models/usuario.dart';

/// Zona predefinida en las playas de Cartagena para ubicación rápida en el mapa.
class ZonaPlaya {
  const ZonaPlaya({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.rx,
    required this.ry,
  });

  final String id;
  final String nombre;
  final String direccion;
  final double latitud;
  final double longitud;

  /// Posición relativa horizontal (0..1) en el selector visual de mapa.
  final double rx;

  /// Posición relativa vertical (0..1) en el selector visual de mapa.
  final double ry;
}

/// Datos iniciales equivalentes a `RandonDataService` y `AdminAccountInitializer`.
class SeedData {
  SeedData._();

  static const List<ZonaPlaya> zonasPlaya = [
    ZonaPlaya(
      id: 'bocagrande',
      nombre: 'Playa de Bocagrande',
      direccion: 'Cra. 1 Playa de Bocagrande, Cartagena de Indias',
      latitud: 10.399667,
      longitud: -75.555001,
      rx: 0.42,
      ry: 0.46,
    ),
    ZonaPlaya(
      id: 'bony',
      nombre: 'Kiosco El Bony',
      direccion: 'Cra. 1, Cartagena de Indias, Bolívar - Kiosco El Bony',
      latitud: 10.394599,
      longitud: -75.557120,
      rx: 0.56,
      ry: 0.54,
    ),
    ZonaPlaya(
      id: 'laguito',
      nombre: 'El Laguito',
      direccion: 'Av. Almirante Brion, Playa El Laguito, Cartagena',
      latitud: 10.391100,
      longitud: -75.562800,
      rx: 0.28,
      ry: 0.66,
    ),
    ZonaPlaya(
      id: 'castillo',
      nombre: 'Castillogrande',
      direccion: 'Cra. 10 Bahía de Castillogrande, Cartagena',
      latitud: 10.394900,
      longitud: -75.551400,
      rx: 0.72,
      ry: 0.36,
    ),
  ];

  static List<Usuario> initialUsuarios() {
    return const [
      Usuario(
        id: 'u-user-1',
        nombreCompleto: 'Cliente PlayApp',
        correo: 'cliente@playapp.co',
        password: '1234',
        rol: RolUsuario.user,
      ),
      Usuario(
        id: 'u-admin-1',
        nombreCompleto: 'Donde Dani',
        correo: 'dondearri@gmail.com',
        password: '1234',
        rol: RolUsuario.admin,
      ),
      Usuario(
        id: 'u-admin-2',
        nombreCompleto: 'Kiosco El Bony',
        correo: 'kioscoelbony@playapp.co',
        password: '1234',
        rol: RolUsuario.admin,
      ),
    ];
  }

  static List<Producto> initialProductos() {
    return const [
      Producto(
        id: 'prod-1',
        nombre: 'Pescado frito',
        descripcion: 'Pescado frito con ensalada fresca y arroz de coco.',
        precio: 32000,
        stock: 25,
        tipo: 4,
        categoria: CategoriaProducto.comida,
        imagenAsset: 'assets/images/catalogo/pescado-frito.jpg',
        entidadNombre: 'Kiosco El Bony',
      ),
      Producto(
        id: 'prod-2',
        nombre: 'Arroz de coco',
        descripcion: 'Arroz de coco tradicional del Caribe colombiano.',
        precio: 12000,
        stock: 40,
        tipo: 1,
        categoria: CategoriaProducto.comida,
        imagenAsset: 'assets/images/catalogo/arroz-coco.jpg',
        entidadNombre: 'Donde Dani',
      ),
      Producto(
        id: 'prod-3',
        nombre: 'Patacones con hogao',
        descripcion: 'Patacones crujientes acompañados con hogao casero.',
        precio: 14000,
        stock: 35,
        tipo: 1,
        categoria: CategoriaProducto.comida,
        imagenAsset: 'assets/images/catalogo/patacones-hogao.jpg',
        entidadNombre: 'Kiosco El Bony',
      ),
      Producto(
        id: 'prod-4',
        nombre: 'Ceviche de camarón',
        descripcion:
            'Ceviche de camarón fresco con limón y galletas saladas.',
        precio: 28000,
        stock: 20,
        tipo: 4,
        categoria: CategoriaProducto.comida,
        imagenAsset: 'assets/images/catalogo/ceviche-camaron.webp',
        entidadNombre: 'Donde Dani',
      ),
      Producto(
        id: 'prod-5',
        nombre: 'Arepa de huevo',
        descripcion: 'Arepa de huevo cartagenera recién preparada.',
        precio: 9000,
        stock: 30,
        tipo: 1,
        categoria: CategoriaProducto.comida,
        imagenAsset: 'assets/images/catalogo/arepa-huevo.jpg',
        entidadNombre: 'Kiosco El Bony',
      ),
      Producto(
        id: 'prod-6',
        nombre: 'Mojarra con patacones',
        descripcion: 'Mojarra frita servida con patacones y ensalada.',
        precio: 35000,
        stock: 18,
        tipo: 4,
        categoria: CategoriaProducto.comida,
        imagenAsset: 'assets/images/catalogo/mojarra-patacones.webp',
        entidadNombre: 'Donde Dani',
      ),
      Producto(
        id: 'prod-7',
        nombre: 'Limonada de coco',
        descripcion: 'Bebida fría de coco y limón ideal para la playa.',
        precio: 10000,
        stock: 50,
        tipo: 4,
        categoria: CategoriaProducto.bebida,
        imagenAsset: 'assets/images/catalogo/limonada-coco.jpg',
        entidadNombre: 'Kiosco El Bony',
      ),
      Producto(
        id: 'prod-8',
        nombre: 'Coco frío',
        descripcion: 'Coco frío natural servido al instante frente al mar.',
        precio: 8000,
        stock: 45,
        tipo: 4,
        categoria: CategoriaProducto.bebida,
        imagenAsset: 'assets/images/catalogo/coco-frio.jpg',
        entidadNombre: 'Donde Dani',
      ),
      Producto(
        id: 'prod-9',
        nombre: 'Jugo de maracuyá',
        descripcion: 'Jugo natural de maracuyá bien frío.',
        precio: 9000,
        stock: 45,
        tipo: 4,
        categoria: CategoriaProducto.bebida,
        imagenAsset: 'assets/images/catalogo/jugo-maracuya.jpg',
        entidadNombre: 'Kiosco El Bony',
      ),
      Producto(
        id: 'prod-10',
        nombre: 'Cerveza nacional',
        descripcion: 'Cerveza fría para disfrutar frente al mar.',
        precio: 7000,
        stock: 60,
        tipo: 1,
        categoria: CategoriaProducto.bebida,
        imagenAsset: 'assets/images/catalogo/cerveza-nacional.webp',
        entidadNombre: 'Donde Dani',
      ),
      Producto(
        id: 'prod-11',
        nombre: 'Carpa playera familiar',
        descripcion:
            'Reserva de carpa con 4 sillas asoleadoras en Playa de Bocagrande.',
        precio: 45000,
        stock: 12,
        tipo: 2,
        categoria: CategoriaProducto.servicio,
        imagenAsset: 'assets/images/ArenaDemas.jpg',
        entidadNombre: 'Kiosco El Bony',
      ),
      Producto(
        id: 'prod-12',
        nombre: 'Moto acuática (30 min)',
        descripcion:
            'Recorrido guiado seguro en moto acuática con chaleco salvavidas.',
        precio: 120000,
        stock: 6,
        tipo: 2,
        categoria: CategoriaProducto.servicio,
        imagenAsset: 'assets/images/Moto.png',
        entidadNombre: 'Donde Dani',
      ),
    ];
  }

  static List<Resena> initialResenas() {
    final now = DateTime.now();
    return [
      Resena(
        id: 'rev-1',
        nombre: 'Laura Martínez',
        valoracion: 5,
        comentario:
            'Excelente servicio en Bocagrande. Saber el precio real desde la app evita cobros exagerados en la playa.',
        fecha: now.subtract(const Duration(hours: 6)),
      ),
      Resena(
        id: 'rev-2',
        nombre: 'Carlos Mendoza',
        valoracion: 5,
        comentario:
            'La mojarra con patacones y la limonada de coco llegaron súper rápido directo a nuestra carpa.',
        fecha: now.subtract(const Duration(days: 1, hours: 3)),
      ),
    ];
  }

  static List<Pedido> initialPedidos() {
    final now = DateTime.now();
    return [
      Pedido(
        id: 'PA1024A8',
        clienteCorreo: 'cliente@playapp.co',
        clienteNombre: 'Cliente PlayApp',
        estado: EstadoPedido.enPreparacion,
        total: 55000,
        timestamp: now.subtract(const Duration(minutes: 35)),
        items: const [
          PedidoItem(
            productoId: 'prod-6',
            nombre: 'Mojarra con patacones',
            precioUnitario: 35000,
            cantidad: 1,
            entidadNombre: 'Donde Dani',
          ),
          PedidoItem(
            productoId: 'prod-7',
            nombre: 'Limonada de coco',
            precioUnitario: 10000,
            cantidad: 2,
            entidadNombre: 'Kiosco El Bony',
          ),
        ],
        pago: Pago(
          metodo: 'Mercado Pago',
          valor: 55000,
          estado: EstadoPago.terminado,
          fecha: now.subtract(const Duration(minutes: 34)),
        ),
        envio: const Envio(
          latitud: 10.399667,
          longitud: -75.555001,
          direccion: 'Cra. 1 Playa de Bocagrande, Cartagena de Indias',
          mesaCarpa: 7,
          descripcion: 'Carpa azul frente al puesto salvavidas.',
        ),
      ),
      Pedido(
        id: 'PA1019B3',
        clienteCorreo: 'cliente@playapp.co',
        clienteNombre: 'Cliente PlayApp',
        estado: EstadoPedido.terminado,
        total: 40000,
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        items: const [
          PedidoItem(
            productoId: 'prod-4',
            nombre: 'Ceviche de camarón',
            precioUnitario: 28000,
            cantidad: 1,
            entidadNombre: 'Donde Dani',
          ),
          PedidoItem(
            productoId: 'prod-2',
            nombre: 'Arroz de coco',
            precioUnitario: 12000,
            cantidad: 1,
            entidadNombre: 'Donde Dani',
          ),
        ],
        pago: Pago(
          metodo: 'DEBITO',
          valor: 40000,
          estado: EstadoPago.terminado,
          fecha: now.subtract(const Duration(days: 1, hours: 2)),
        ),
        envio: const Envio(
          latitud: 10.394599,
          longitud: -75.557120,
          direccion: 'Cra. 1, Cartagena de Indias, Bolívar - Kiosco El Bony',
          mesaCarpa: 3,
          descripcion: 'Mesa junto a la sombrilla blanca.',
        ),
      ),
    ];
  }
}
