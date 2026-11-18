class AdminMonthlyRevenue {
  final int anio;
  final int mes;
  final String periodo;
  final int pedidos;
  final double ingresos;

  AdminMonthlyRevenue({
    required this.anio,
    required this.mes,
    required this.periodo,
    required this.pedidos,
    required this.ingresos,
  });

  factory AdminMonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return AdminMonthlyRevenue(
      anio: (json['anio'] is num) ? (json['anio'] as num).toInt() : 0,
      mes: (json['mes'] is num) ? (json['mes'] as num).toInt() : 0,
      periodo: (json['periodo'] ?? '').toString(),
      pedidos: (json['pedidos'] is num) ? (json['pedidos'] as num).toInt() : 0,
      ingresos: (json['ingresos'] is num) ? (json['ingresos'] as num).toDouble() : 0.0,
    );
  }
}

class AdminTopProduct {
  final String id;
  final String nombre;
  final double precio;
  final int cantidadVendida;
  final double ingresosGenerados;

  AdminTopProduct({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.cantidadVendida,
    required this.ingresosGenerados,
  });

  factory AdminTopProduct.fromJson(Map<String, dynamic> json) {
    final rawCant = json['cantidadVendida'] ?? json['cantidad'] ?? 0;
    final cant = (rawCant is num) ? rawCant.toInt() : 0;
    final total = (json['ingresos'] is num)
        ? (json['ingresos'] as num).toDouble()
        : ((json['ingresosGenerados'] is num) ? (json['ingresosGenerados'] as num).toDouble() : 0.0);

    double unitPrice = 0.0;
    if (json['precioUnitario'] is num && (json['precioUnitario'] as num) > 0) {
      unitPrice = (json['precioUnitario'] as num).toDouble();
    } else if (json['precio'] is num && (json['precio'] as num) > 0) {
      unitPrice = (json['precio'] as num).toDouble();
    } else if (cant > 0 && total > 0) {
      unitPrice = total / cant;
    }

    return AdminTopProduct(
      id: (json['productoId'] ?? json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? 'Producto').toString(),
      precio: unitPrice,
      cantidadVendida: cant,
      ingresosGenerados: total,
    );
  }
}

class AdminReportModel {
  final int totalPedidos;
  final double ingresosTotales;
  final double promedioProductosPorPedido;
  final List<AdminMonthlyRevenue> ingresosMensuales;
  final List<AdminTopProduct> productosTop;

  AdminReportModel({
    required this.totalPedidos,
    required this.ingresosTotales,
    required this.promedioProductosPorPedido,
    required this.ingresosMensuales,
    required this.productosTop,
  });

  factory AdminReportModel.fromJson(Map<String, dynamic> json) {
    int totalP = 0;
    double ingresosT = 0.0;
    double promedioP = 0.0;
    List<AdminMonthlyRevenue> monthlyList = [];
    List<AdminTopProduct> topList = [];

    if (json['pedidos'] is Map) {
      final p = json['pedidos'] as Map<String, dynamic>;
      totalP = (p['totalPedidos'] is num) ? (p['totalPedidos'] as num).toInt() : 0;
      ingresosT = (p['ingresosTotales'] is num) ? (p['ingresosTotales'] as num).toDouble() : 0.0;
      promedioP = (p['promedioProductosPorPedido'] is num)
          ? (p['promedioProductosPorPedido'] as num).toDouble()
          : 0.0;

      if (p['ingresosMensuales'] is List) {
        for (final m in p['ingresosMensuales']) {
          if (m is Map<String, dynamic>) {
            monthlyList.add(AdminMonthlyRevenue.fromJson(m));
          }
        }
      }
    }

    if (json['productosTop'] is List) {
      for (final t in json['productosTop']) {
        if (t is Map<String, dynamic>) {
          topList.add(AdminTopProduct.fromJson(t));
        }
      }
    }

    return AdminReportModel(
      totalPedidos: totalP,
      ingresosTotales: ingresosT,
      promedioProductosPorPedido: promedioP,
      ingresosMensuales: monthlyList,
      productosTop: topList,
    );
  }
}
