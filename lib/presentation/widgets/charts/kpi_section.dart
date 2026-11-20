import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/sales_charts_model.dart';
import 'charts_common.dart';

/// Métrica mostrada en la gráfica de tendencia (se elige también tocando un indicador).
enum TrendMetric { ingresos, pedidos, unidades, ticket }

extension TrendMetricInfo on TrendMetric {
  String get label => switch (this) {
        TrendMetric.ingresos => 'Ingresos',
        TrendMetric.pedidos => 'Pedidos',
        TrendMetric.unidades => 'Unidades',
        TrendMetric.ticket => 'Ticket promedio',
      };

  bool get isMoney => this == TrendMetric.ingresos || this == TrendMetric.ticket;

  String format(double v, {bool compact = false}) =>
      isMoney ? (compact ? formatMoneyCompact(v) : formatMoney(v)) : formatNumber(v);

  List<double> series(ChartsTrend t) => switch (this) {
        TrendMetric.ingresos => t.ingresos,
        TrendMetric.pedidos => t.pedidos,
        TrendMetric.unidades => t.unidades,
        TrendMetric.ticket => t.ticket,
      };

  List<double?>? previous(ChartsTrend t) {
    switch (this) {
      case TrendMetric.ingresos:
        return t.ingresosAnterior;
      case TrendMetric.pedidos:
        return t.pedidosAnterior;
      case TrendMetric.unidades:
        return t.unidadesAnterior;
      case TrendMetric.ticket:
        final ia = t.ingresosAnterior;
        final pa = t.pedidosAnterior;
        if (ia == null || pa == null) return null;
        return [
          for (var i = 0; i < ia.length; i++)
            (ia[i] == null || pa[i] == null) ? null : (pa[i]! > 0 ? ia[i]! / pa[i]! : 0),
        ];
    }
  }

  KpiValue kpi(SalesChartsData d) => switch (this) {
        TrendMetric.ingresos => d.ingresos,
        TrendMetric.pedidos => d.pedidos,
        TrendMetric.unidades => d.unidades,
        TrendMetric.ticket => d.ticketPromedio,
      };

  IconData get icon => switch (this) {
        TrendMetric.ingresos => Icons.payments_rounded,
        TrendMetric.pedidos => Icons.receipt_long_rounded,
        TrendMetric.unidades => Icons.inventory_2_rounded,
        TrendMetric.ticket => Icons.local_offer_rounded,
      };
}

/// Gráfica 1: indicadores clave con cambio frente al periodo anterior y mini tendencia.
class KpiSection extends StatelessWidget {
  final SalesChartsData data;
  final TrendMetric selected;
  final ValueChanged<TrendMetric> onSelect;

  const KpiSection({super.key, required this.data, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 640 ? 4 : 2;
        const gap = 10.0;
        final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final m in TrendMetric.values)
              SizedBox(
                width: w,
                child: _KpiTile(
                  metric: m,
                  value: m.kpi(data),
                  series: m.series(data.trend),
                  hasPrevious: data.hasPrevious,
                  selected: m == selected,
                  onTap: () => onSelect(m),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  final TrendMetric metric;
  final KpiValue value;
  final List<double> series;
  final bool hasPrevious;
  final bool selected;
  final VoidCallback onTap;

  const _KpiTile({
    required this.metric,
    required this.value,
    required this.series,
    required this.hasPrevious,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.primaryDark;
    return Semantics(
      button: true,
      selected: selected,
      label: '${metric.label}: ${metric.format(value.actual)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.primary : AppColors.sandBorder, width: selected ? 1.6 : 1),
            boxShadow: selected
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(metric.icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      metric.label,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  metric.format(value.actual),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  ChangeBadge(cambioPct: value.cambioPct),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      !hasPrevious
                          ? 'sin comparación'
                          : value.anterior == null || value.anterior == 0
                              ? 'antes: 0'
                              : 'antes: ${metric.format(value.anterior!, compact: true)}',
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(height: 32, child: _Sparkline(values: series, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  const _Sparkline({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    final pts = values.length == 1 ? [values.first, values.first] : values;
    final maxV = pts.fold<double>(0, (a, b) => b > a ? b : a);
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (pts.length - 1).toDouble().clamp(1, double.infinity),
        minY: 0,
        maxY: maxV <= 0 ? 1 : maxV * 1.1,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < pts.length; i++) FlSpot(i.toDouble(), pts[i])],
            isCurved: true,
            preventCurveOverShooting: true,
            curveSmoothness: 0.25,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}
