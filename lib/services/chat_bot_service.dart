import '../models/pedido.dart';
import '../models/producto.dart';
import '../theme/playapp_theme.dart';

/// Motor local de intenciones inspirado en `ChatIntentService.java` de PlayApp.
class ChatBotService {
  const ChatBotService._();

  static const _refreshingKeywords = [
    'refrescante',
    'refrescantes',
    'frio',
    'fria',
    'frias',
    'frios',
    'helado',
    'helada',
    'calor',
    'bebida',
    'bebidas',
    'jugo',
    'jugos',
    'refresco',
    'refrescos',
    'limonada',
    'gaseosa',
    'cerveza',
    'coco',
  ];

  static const _foodKeywords = [
    'comida',
    'comidas',
    'almuerzo',
    'cena',
    'desayuno',
    'arepa',
    'pescado',
    'mojarra',
    'ceviche',
    'patacones',
    'arroz',
  ];

  static const _serviceKeywords = [
    'servicio',
    'servicios',
    'carpa',
    'sombrilla',
    'mesa',
    'moto',
    'alquiler',
  ];

  static const _stopWords = {
    'de',
    'del',
    'la',
    'las',
    'el',
    'los',
    'un',
    'una',
    'unos',
    'unas',
    'por',
    'para',
    'me',
    'quiero',
    'muestrame',
    'muestreme',
    'que',
    'cual',
    'cuanto',
    'vale',
    'cuesta',
    'precio',
    'precios',
    'valor',
    'tienen',
    'hay',
  };

  /// Genera la respuesta del Asistente PlayApp según el mensaje y estado en vivo.
  static String responder({
    required String mensaje,
    required List<Producto> productos,
    required List<Pedido> pedidos,
    required int itemsEnCarrito,
    required String? usuarioNombre,
  }) {
    final norm = _normalize(mensaje);
    if (norm.isEmpty) {
      return 'Escribe tu consulta y te ayudo con productos, precios o pedidos.';
    }

    if (_containsAny(norm, ['hola', 'buenas', 'buenos dias', 'buenas tardes'])) {
      final saludo = (usuarioNombre != null && usuarioNombre.isNotEmpty)
          ? '¡Hola, $usuarioNombre!'
          : '¡Hola!';
      return '$saludo Soy el Asistente PlayApp. Te ayudo a evitar sobreprecios en playa, consultar precios, recomendar bebidas o revisar tus pedidos.';
    }

    if (_containsAny(norm, ['pedido', 'pedidos', 'estado', 'orden', 'compra', 'carrito'])) {
      return _buildPedidosResponse(pedidos, itemsEnCarrito);
    }

    if (_containsAny(norm, ['precio', 'precios', 'cuanto cuesta', 'cuanto vale', 'valor'])) {
      return _buildPriceResponse(norm, productos);
    }

    if (_containsAny(norm, ['recom', 'suger', 'opcion', 'opciones', 'producto', 'productos', 'tienen', 'muestrame', 'menu', 'catalogo']) ||
        _containsAny(norm, _refreshingKeywords) ||
        _containsAny(norm, _foodKeywords) ||
        _containsAny(norm, _serviceKeywords)) {
      return _buildProductResponse(norm, productos);
    }

    if (_containsAny(norm, ['metodo de pago', 'pago', 'pagos', 'tarjeta', 'efectivo', 'mercado'])) {
      return 'Métodos de pago disponibles: Mercado Pago, tarjeta débito/crédito y efectivo en playa.';
    }

    if (_containsAny(norm, ['horario', 'hora', 'abren', 'cierran'])) {
      return 'El horario depende de cada vendedor en playa (generalmente de 8:00 a.m. a 6:00 p.m.). Puedes validar disponibilidad al momento de pedir.';
    }

    if (_containsAny(norm, ['donde', 'ubicacion', 'cobertura', 'playa', 'cartagena', 'estafa'])) {
      return 'PlayApp conecta comida, bebidas y servicios con precios claros en playas de Cartagena (Bocagrande, El Laguito, Castillogrande y Kiosco El Bony).';
    }

    return 'Puedo ayudarte con:\n• Recomendaciones de comida, bebidas frías o servicios\n• Consulta de precios reales en playa\n• Estado de tus pedidos y carrito\n• Métodos de pago y zonas en Cartagena';
  }

  static String _buildPedidosResponse(List<Pedido> pedidos, int carritoItems) {
    if (pedidos.isEmpty) {
      return 'No tienes pedidos registrados por ahora. En tu carrito tienes $carritoItems ítem(s).';
    }
    final recientes = [...pedidos]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final buffer = StringBuffer('Estado de tus pedidos recientes:\n');
    for (final pedido in recientes.take(3)) {
      buffer.writeln(
        '- Pedido #${pedido.id}: ${pedido.estado.etiqueta} | Pago: ${pedido.pago.estado.etiqueta} | ${formatCop(pedido.total)}',
      );
    }
    buffer.write('Ítems en carrito actual: $carritoItems.');
    return buffer.toString().trim();
  }

  static String _buildPriceResponse(String norm, List<Producto> productos) {
    final target = _cleanTerm(norm);
    final matches = _rankProducts(norm, target, productos, null).take(3).toList();
    if (matches.isEmpty) {
      return 'No encontré precios para "$target" en el inventario actual. Prueba con pescado, mojarra, ceviche, limonada de coco o carpa.';
    }
    if (matches.length == 1) {
      final p = matches.first;
      return 'El precio oficial de ${p.nombre} es ${formatCop(p.precio)} (${p.entidadNombre}, ${p.stock} disponibles).';
    }
    final buffer = StringBuffer('Precios oficiales en PlayApp:\n');
    for (final p in matches) {
      buffer.writeln('- ${p.nombre}: ${formatCop(p.precio)}');
    }
    return buffer.toString().trim();
  }

  static String _buildProductResponse(String norm, List<Producto> productos) {
    CategoriaProducto? category;
    String title = 'Recomendaciones PlayApp';

    if (_containsAny(norm, _refreshingKeywords)) {
      category = CategoriaProducto.bebida;
      title = 'Opciones refrescantes y bebidas frías';
    } else if (_containsAny(norm, _serviceKeywords)) {
      category = CategoriaProducto.servicio;
      title = 'Servicios disponibles en playa';
    } else if (_containsAny(norm, _foodKeywords)) {
      category = CategoriaProducto.comida;
      title = 'Comida típica cartagenera';
    }

    final term = _cleanTerm(norm);
    final matches = _rankProducts(norm, term, productos, category).take(5).toList();
    if (matches.isEmpty) {
      return 'No encontré productos disponibles para esa solicitud en este momento.';
    }
    final buffer = StringBuffer('$title:\n');
    for (final p in matches) {
      buffer.writeln('- ${p.nombre} | ${formatCop(p.precio)} (${p.stock} disp.)');
    }
    return buffer.toString().trim();
  }

  static List<Producto> _rankProducts(
    String norm,
    String term,
    List<Producto> productos,
    CategoriaProducto? category,
  ) {
    final scored = <({Producto product, int score})>[];
    final termTokens = term.split(' ').where((t) => t.length >= 3).toList();

    for (final p in productos) {
      var score = 0;
      final name = _normalize(p.nombre);
      final desc = _normalize(p.descripcion);

      if (category != null && p.categoria == category) score += 35;
      if (term.isNotEmpty) {
        if (name == term) score += 200;
        if (name.contains(term)) score += 140;
        if (desc.contains(term)) score += 90;
        for (final token in termTokens) {
          if (name.contains(token)) score += 55;
          if (desc.contains(token)) score += 30;
        }
      } else if (category != null && p.categoria == category) {
        score += 20;
      }

      if (category == null && term.isEmpty) {
        score += 10;
      }
      if (p.stock > 0) score += 8;

      if (score > 0) {
        scored.add((product: p, score: score));
      }
    }

    scored.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      return cmp != 0 ? cmp : a.product.nombre.compareTo(b.product.nombre);
    });
    return scored.map((e) => e.product).toList();
  }

  static String _cleanTerm(String norm) {
    final cleaned = norm.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    final tokens = cleaned
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && !_stopWords.contains(t))
        .where((t) => !{'recomienda', 'recomiendas', 'dame', 'ver', 'mostrar'}.contains(t))
        .toList();
    return tokens.join(' ');
  }

  static String _normalize(String value) {
    const replacements = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    var out = value.toLowerCase().trim();
    replacements.forEach((k, v) => out = out.replaceAll(k, v));
    return out;
  }

  static bool _containsAny(String message, List<String> terms) {
    return terms.any(message.contains);
  }
}
