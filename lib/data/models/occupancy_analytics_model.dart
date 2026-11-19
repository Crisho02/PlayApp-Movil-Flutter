/// Analítica de la red neuronal de ocupación (escenarios sintéticos evaluados por el modelo).
/// El parseo es defensivo: valores ausentes o mal formados nunca lanzan, se descartan.
library;

double _num(dynamic v, [double fallback = 0]) {
  if (v is num && v.isFinite) return v.toDouble();
  return fallback;
}

List<double> _numList(dynamic v) {
  if (v is! List) return const [];
  return v.map((e) => _num(e)).toList(growable: false);
}

String _str(dynamic v) => (v ?? '').toString();

class AnalyticsOption {
  final String id;
  final String label;
  const AnalyticsOption(this.id, this.label);
}

class HourlyAnalytics {
  final List<AnalyticsOption> dayTypes;
  final List<AnalyticsOption> conditions;

  /// series[dayTypeId][conditionId] -> 24 valores (% de ocupación por hora).
  final Map<String, Map<String, List<double>>> series;

  const HourlyAnalytics({required this.dayTypes, required this.conditions, required this.series});

  List<double> curve(String dayId, String conditionId) {
    final c = series[dayId]?[conditionId];
    return (c != null && c.length == 24) ? c : const [];
  }

  bool get isValid =>
      dayTypes.isNotEmpty &&
      conditions.isNotEmpty &&
      dayTypes.every((d) => conditions.every((c) => curve(d.id, c.id).length == 24));

  factory HourlyAnalytics.fromJson(Map<String, dynamic> json) {
    List<AnalyticsOption> options(dynamic raw) => raw is List
        ? raw
            .whereType<Map>()
            .map((m) => AnalyticsOption(_str(m['id']), _str(m['label'])))
            .where((o) => o.id.isNotEmpty)
            .toList(growable: false)
        : const [];
    final series = <String, Map<String, List<double>>>{};
    final rawSeries = json['series'];
    if (rawSeries is Map) {
      rawSeries.forEach((day, conds) {
        if (conds is Map) {
          series[_str(day)] = {for (final e in conds.entries) _str(e.key): _numList(e.value)};
        }
      });
    }
    return HourlyAnalytics(
      dayTypes: options(json['dayTypes']),
      conditions: options(json['conditions']),
      series: series,
    );
  }
}

class HeatmapAnalytics {
  final List<String> days;
  final List<AnalyticsOption> seasons;

  /// values[seasonId] -> 7 filas (lunes a domingo) x 24 horas.
  final Map<String, List<List<double>>> values;

  const HeatmapAnalytics({required this.days, required this.seasons, required this.values});

  List<List<double>> grid(String seasonId) => values[seasonId] ?? const [];

  /// Valor máximo entre todas las temporadas: fija una escala de color común para compararlas.
  double get maxValue {
    var m = 0.0;
    for (final g in values.values) {
      for (final row in g) {
        for (final v in row) {
          if (v > m) m = v;
        }
      }
    }
    return m;
  }

  bool get isValid =>
      days.length == 7 &&
      seasons.isNotEmpty &&
      seasons.every((s) {
        final g = grid(s.id);
        return g.length == 7 && g.every((r) => r.length == 24);
      });

  factory HeatmapAnalytics.fromJson(Map<String, dynamic> json) {
    final values = <String, List<List<double>>>{};
    final raw = json['values'];
    if (raw is Map) {
      raw.forEach((season, rows) {
        if (rows is List) values[_str(season)] = rows.map(_numList).toList(growable: false);
      });
    }
    return HeatmapAnalytics(
      days: json['days'] is List ? (json['days'] as List).map(_str).toList(growable: false) : const [],
      seasons: json['seasons'] is List
          ? (json['seasons'] as List)
              .whereType<Map>()
              .map((m) => AnalyticsOption(_str(m['id']), _str(m['label'])))
              .where((o) => o.id.isNotEmpty)
              .toList(growable: false)
          : const [],
      values: values,
    );
  }
}

class SensitivityOption {
  final String label;
  final double value;
  final double delta;
  const SensitivityOption({required this.label, required this.value, required this.delta});
}

class SensitivityFactor {
  final String id;
  final String label;
  final double impact;
  final List<SensitivityOption> options;
  const SensitivityFactor({required this.id, required this.label, required this.impact, required this.options});
}

class SensitivityBase {
  final String id;
  final String label;
  final double baseline;
  final List<SensitivityFactor> factors;
  const SensitivityBase({required this.id, required this.label, required this.baseline, required this.factors});

  factory SensitivityBase.fromJson(Map<String, dynamic> json) {
    final factors = <SensitivityFactor>[];
    if (json['factors'] is List) {
      for (final f in (json['factors'] as List).whereType<Map>()) {
        final options = <SensitivityOption>[];
        if (f['options'] is List) {
          for (final o in (f['options'] as List).whereType<Map>()) {
            options.add(SensitivityOption(label: _str(o['label']), value: _num(o['value']), delta: _num(o['delta'])));
          }
        }
        if (options.isNotEmpty) {
          factors.add(SensitivityFactor(
            id: _str(f['id']),
            label: _str(f['label']),
            impact: _num(f['impact']),
            options: options,
          ));
        }
      }
    }
    return SensitivityBase(
      id: _str(json['id']),
      label: _str(json['label']),
      baseline: _num(json['baseline']),
      factors: factors,
    );
  }
}

class ModelEvaluation {
  final double mae;
  final double baselineMae;
  final double dayMae;
  final double nightMae;
  const ModelEvaluation({required this.mae, required this.baselineMae, required this.dayMae, required this.nightMae});

  factory ModelEvaluation.fromJson(Map<String, dynamic> json) => ModelEvaluation(
        mae: _num(json['mae']),
        baselineMae: _num(json['baselineMae']),
        dayMae: _num(json['dayMae']),
        nightMae: _num(json['nightMae']),
      );
}

class OccupancyAnalytics {
  final String modelVersion;
  final String notice;
  final ModelEvaluation? evaluation;
  final HourlyAnalytics hourly;
  final HeatmapAnalytics heatmap;
  final List<SensitivityBase> sensitivity;

  const OccupancyAnalytics({
    required this.modelVersion,
    required this.notice,
    required this.evaluation,
    required this.hourly,
    required this.heatmap,
    required this.sensitivity,
  });

  /// Devuelve null si la respuesta no trae datos completos y consistentes para las 3 gráficas.
  static OccupancyAnalytics? tryParse(Map<String, dynamic> json) {
    try {
      if (json['available'] != true) return null;
      final hourly = HourlyAnalytics.fromJson(Map<String, dynamic>.from(json['hourly'] as Map));
      final heatmap = HeatmapAnalytics.fromJson(Map<String, dynamic>.from(json['heatmap'] as Map));
      final bases = ((json['sensitivity'] as Map)['bases'] as List)
          .whereType<Map>()
          .map((b) => SensitivityBase.fromJson(Map<String, dynamic>.from(b)))
          .where((b) => b.id.isNotEmpty && b.factors.isNotEmpty)
          .toList(growable: false);
      if (!hourly.isValid || !heatmap.isValid || bases.isEmpty) return null;
      final eval = json['evaluation'];
      return OccupancyAnalytics(
        modelVersion: _str(json['modelVersion']),
        notice: _str(json['notice']),
        evaluation: (eval is Map && eval.isNotEmpty)
            ? ModelEvaluation.fromJson(Map<String, dynamic>.from(eval))
            : null,
        hourly: hourly,
        heatmap: heatmap,
        sensitivity: bases,
      );
    } catch (_) {
      return null;
    }
  }
}
