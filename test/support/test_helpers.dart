import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playapp_movil_flutter/data/models/admin_weather_model.dart';
import 'package:playapp_movil_flutter/data/models/sales_charts_model.dart';
import 'package:playapp_movil_flutter/providers/admin_provider.dart';

/// Respuestas REALES de GET /api/admin/charts (base de datos del proyecto, 19/11/2026).
Map<String, dynamic> loadChartsJson(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

SalesChartsData loadCharts(String name) => SalesChartsData.tryParse(loadChartsJson(name))!;

/// Proveedor falso: sin red, con estado controlado por la prueba.
class FakeAdminProvider extends AdminProvider {
  AdminWeatherModel? fakeWeather;
  SalesChartsData? fakeCharts;
  String? fakeChartsError;
  bool fakeChartsLoading;
  ChartsFilter fakeFilter;
  final List<ChartsFilter?> fetchCalls = [];

  FakeAdminProvider({
    this.fakeWeather,
    this.fakeCharts,
    this.fakeChartsError,
    this.fakeChartsLoading = false,
    this.fakeFilter = const ChartsFilter(),
  });

  @override
  AdminWeatherModel? get weather => fakeWeather;
  @override
  SalesChartsData? get salesCharts => fakeCharts;
  @override
  String? get chartsError => fakeChartsError;
  @override
  bool get isChartsLoading => fakeChartsLoading;
  @override
  ChartsFilter get chartsFilter => fakeFilter;

  @override
  Future<void> fetchSalesCharts({ChartsFilter? filter}) async {
    fetchCalls.add(filter);
    if (filter != null) fakeFilter = filter;
    notifyListeners(); // como el proveedor real
  }

  @override
  Future<void> fetchAdminData() async {}
  @override
  Future<void> fetchMetrics() async {}
}

void setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Falla mostrando el detalle completo si hubo un desborde u otro error de render.
void expectClean(WidgetTester tester, [String? reason]) {
  final e = tester.takeException();
  if (e != null) {
    fail('${reason ?? ''} ${e is FlutterError ? e.toStringDeep() : e}');
  }
}

const mobileSizes = <Size>[Size(320, 640), Size(360, 800), Size(412, 915), Size(768, 1024)];
