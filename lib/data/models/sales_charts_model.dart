/// Datos de la pestaña "Gráficos", calculados en vivo desde la base de datos (GET /api/admin/charts).
/// El parseo es defensivo: si la respuesta llega incompleta o inconsistente, [SalesChartsData.tryParse]
/// devuelve null y la pantalla muestra un error en lugar de una gráfica equivocada.
library;

double _num(dynamic v, [double fallback = 0]) => (v is num && v.isFinite) ? v.toDouble() : fallback;

double? _numOrNull(dynamic v) => (v is num && v.isFinite) ? v.toDouble() : null;

int? _intOrNull(dynamic v) => v is num ? v.toInt() : null;

String _str(dynamic v) => (v ?? '').toString();

List<double> _numList(dynamic v) => v is List ? v.map((e) => _num(e)).toList(growable: false) : const [];

List<double?>? _nullableList(dynamic v) => v is List ? v.map(_numOrNull).toList(growable: false) : null;

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Filtros que se envían al backend.
class ChartsFilter {
  /// 7d | 30d | 90d | 365d | todo | personalizado
  final String rango;
  final DateTime? desde;
  final DateTime? hasta;

  /// 1 Comida, 2 Bebida, 3 Servicio; null = todas.
  final int? categoria;

  /// auto | day | week | month
  final String granularidad;

  const ChartsFilter({
    this.rango = '30d',
    this.desde,
    this.hasta,
    this.categoria,
    this.granularidad = 'auto',
  });

  ChartsFilter copyWith({
    String? rango,
    DateTime? desde,
    DateTime? hasta,
    int? categoria,
    bool clearCategoria = false,
    String? granularidad,
  }) {
    return ChartsFilter(
      rango: rango ?? this.rango,
      desde: desde ?? this.desde,
      hasta: hasta ?? this.hasta,
      categoria: clearCategoria ? null : (categoria ?? this.categoria),
      granularidad: granularidad ?? this.granularidad,
    );
  }

  Map<String, String> toQuery() => {
        'rango': rango,
        if (rango == 'personalizado' && desde != null) 'desde': _ymd(desde!),
        if (rango == 'personalizado' && hasta != null) 'hasta': _ymd(hasta!),
        if (categoria != null) 'categoria': '$categoria',
        'granularidad': granularidad,
      };
}

class KpiValue {
  final double actual;
  final double? anterior;
  final double? cambioPct;

  const KpiValue({required this.actual, this.anterior, this.cambioPct});

  factory KpiValue.fromJson(dynamic json) {
    final m = json is Map ? json : const {};
    return KpiValue(actual: _num(m['actual']), anterior: _numOrNull(m['anterior']), cambioPct: _numOrNull(m['cambioPct']));
  }
}

class ChartsTrend {
  final List<String> labels;
  final List<double> ingresos;
  final List<double> pedidos;
  final List<double> unidades;
  final List<double?>? ingresosAnterior;
  final List<double?>? pedidosAnterior;
  final List<double?>? unidadesAnterior;

  const ChartsTrend({
    required this.labels,
    required this.ingresos,
    required this.pedidos,
    required this.unidades,
    this.ingresosAnterior,
    this.pedidosAnterior,
    this.unidadesAnterior,
  });

  /// Ticket promedio por periodo (ingresos / pedidos).
  List<double> get ticket => [
        for (var i = 0; i < labels.length; i++) pedidos[i] > 0 ? ingresos[i] / pedidos[i] : 0,
      ];

  bool get hasPrevious => ingresosAnterior != null;

  bool get isValid {
    final n = labels.length;
    bool ok(List? l) => l == null || l.length == n;
    return n > 0 && ingresos.length == n && pedidos.length == n && unidades.length == n &&
        ok(ingresosAnterior) && ok(pedidosAnterior) && ok(unidadesAnterior);
  }

  factory ChartsTrend.fromJson(Map json) => ChartsTrend(
        labels: json['labels'] is List ? (json['labels'] as List).map(_str).toList(growable: false) : const [],
        ingresos: _numList(json['ingresos']),
        pedidos: _numList(json['pedidos']),
        unidades: _numList(json['unidades']),
        ingresosAnterior: _nullableList(json['ingresosAnterior']),
        pedidosAnterior: _nullableList(json['pedidosAnterior']),
        unidadesAnterior: _nullableList(json['unidadesAnterior']),
      );
}

class ChartProduct {
  final String id;
  final String nombre;
  final int? categoria;
  final String categoriaNombre;
  final double? precio;
  final double? stock;
  final bool activo;
  final double unidades;
  final double ingresos;
  final int pedidos;
  final double ticketPromedio;
  final double frecuenciaPct;
  final List<double> serieUnidades;
  final List<double> serieIngresos;

  const ChartProduct({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.categoriaNombre,
    required this.precio,
    required this.stock,
    required this.activo,
    required this.unidades,
    required this.ingresos,
    required this.pedidos,
    required this.ticketPromedio,
    required this.frecuenciaPct,
    required this.serieUnidades,
    required this.serieIngresos,
  });

  /// Porcentaje de rotación: unidades vendidas frente a (vendidas + stock actual). null si no hay stock.
  double? get rotacionPct {
    if (stock == null) return null;
    final base = unidades + stock!;
    return base <= 0 ? 0 : unidades * 100 / base;
  }

  factory ChartProduct.fromJson(Map json) => ChartProduct(
        id: _str(json['id']),
        nombre: _str(json['nombre']).isEmpty ? 'Sin nombre' : _str(json['nombre']),
        categoria: _intOrNull(json['categoria']),
        categoriaNombre: _str(json['categoriaNombre']).isEmpty ? 'Otros' : _str(json['categoriaNombre']),
        precio: _numOrNull(json['precio']),
        stock: _numOrNull(json['stock']),
        activo: json['activo'] != false,
        unidades: _num(json['unidades']),
        ingresos: _num(json['ingresos']),
        pedidos: _num(json['pedidos']).toInt(),
        ticketPromedio: _num(json['ticketPromedio']),
        frecuenciaPct: _num(json['frecuenciaPct']),
        serieUnidades: _numList(json['serieUnidades']),
        serieIngresos: _numList(json['serieIngresos']),
      );
}

class CategoryShare {
  final int id;
  final String nombre;
  final double ingresos;
  final double unidades;
  final int pedidos;

  const CategoryShare({required this.id, required this.nombre, required this.ingresos, required this.unidades, required this.pedidos});

  factory CategoryShare.fromJson(Map json) => CategoryShare(
        id: _intOrNull(json['id']) ?? 0,
        nombre: _str(json['nombre']).isEmpty ? 'Otros' : _str(json['nombre']),
        ingresos: _num(json['ingresos']),
        unidades: _num(json['unidades']),
        pedidos: _num(json['pedidos']).toInt(),
      );
}

class SalesChartsData {
  final DateTime? generatedAt;
  final String rango;
  final DateTime desde;
  final DateTime hasta;
  final String granularidad;
  final int? categoria;
  final DateTime? anteriorDesde;
  final DateTime? anteriorHasta;
  final Map<int, String> categories;
  final KpiValue ingresos;
  final KpiValue pedidos;
  final KpiValue ticketPromedio;
  final KpiValue unidades;
  final ChartsTrend trend;
  final List<ChartProduct> products;
  final List<List<double>> heatmapPedidos;
  final List<List<double>> heatmapIngresos;
  final List<CategoryShare> categoryMix;
  final int pedidosAnalizados;

  const SalesChartsData({
    required this.generatedAt,
    required this.rango,
    required this.desde,
    required this.hasta,
    required this.granularidad,
    required this.categoria,
    required this.anteriorDesde,
    required this.anteriorHasta,
    required this.categories,
    required this.ingresos,
    required this.pedidos,
    required this.ticketPromedio,
    required this.unidades,
    required this.trend,
    required this.products,
    required this.heatmapPedidos,
    required this.heatmapIngresos,
    required this.categoryMix,
    required this.pedidosAnalizados,
  });

  bool get hasPrevious => anteriorDesde != null;
  bool get isEmpty => pedidosAnalizados == 0;

  static List<List<double>>? _matrix(dynamic v) {
    if (v is! List || v.length != 7) return null;
    final rows = v.map(_numList).toList(growable: false);
    return rows.every((r) => r.length == 24) ? rows : null;
  }

  static SalesChartsData? tryParse(Map<String, dynamic> json) {
    try {
      final filters = json['filters'] as Map;
      final desde = _date(filters['desde']);
      final hasta = _date(filters['hasta']);
      if (desde == null || hasta == null) return null;

      final trend = ChartsTrend.fromJson(json['trend'] as Map);
      if (!trend.isValid) return null;

      final n = trend.labels.length;
      final products = (json['products'] as List)
          .whereType<Map>()
          .map(ChartProduct.fromJson)
          .toList(growable: false);
      if (products.any((p) => p.serieIngresos.length != n || p.serieUnidades.length != n)) return null;

      final heat = json['heatmap'] as Map;
      final hp = _matrix(heat['pedidos']);
      final hi = _matrix(heat['ingresos']);
      if (hp == null || hi == null) return null;

      final kpis = json['kpis'] as Map;
      final categories = <int, String>{};
      if (json['categories'] is List) {
        for (final c in (json['categories'] as List).whereType<Map>()) {
          final id = _intOrNull(c['id']);
          if (id != null) categories[id] = _str(c['nombre']);
        }
      }
      final resumen = json['resumen'] is Map ? json['resumen'] as Map : const {};

      return SalesChartsData(
        generatedAt: _date(json['generatedAt']),
        rango: _str(filters['rango']),
        desde: desde,
        hasta: hasta,
        granularidad: _str(filters['granularidad']),
        categoria: _intOrNull(filters['categoria']),
        anteriorDesde: _date(filters['anteriorDesde']),
        anteriorHasta: _date(filters['anteriorHasta']),
        categories: categories,
        ingresos: KpiValue.fromJson(kpis['ingresos']),
        pedidos: KpiValue.fromJson(kpis['pedidos']),
        ticketPromedio: KpiValue.fromJson(kpis['ticketPromedio']),
        unidades: KpiValue.fromJson(kpis['unidades']),
        trend: trend,
        products: products,
        heatmapPedidos: hp,
        heatmapIngresos: hi,
        categoryMix: (json['categoryMix'] as List).whereType<Map>().map(CategoryShare.fromJson).toList(growable: false),
        pedidosAnalizados: _num(resumen['pedidos']).toInt(),
      );
    } catch (_) {
      return null;
    }
  }
}
