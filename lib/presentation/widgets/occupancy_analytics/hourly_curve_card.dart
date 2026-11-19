import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/occupancy_analytics_model.dart';
import 'analytics_common.dart';

const Map<String, Color> _conditionColors = {
  'clear': AppColors.warning,
  'cloudy': Color(0xFF64748B),
  'rain': AppColors.primary,
};
const List<Color> _fallbackColors = [AppColors.turquoise, AppColors.coral, AppColors.primaryDark];

/// Gráfica 1: curva de ocupación por hora. Selector de tipo de día + condiciones activables.
class HourlyCurveCard extends StatefulWidget {
  final HourlyAnalytics data;

  /// Hora local actual (Bogotá) para marcar "Ahora"; inyectable para pruebas.
  final int? nowHour;

  const HourlyCurveCard({super.key, required this.data, this.nowHour});

  @override
  State<HourlyCurveCard> createState() => _HourlyCurveCardState();
}

class _HourlyCurveCardState extends State<HourlyCurveCard> {
  int _dayIndex = 0;
  final Set<String> _hidden = {};

  Color _colorFor(int index, String id) =>
      _conditionColors[id] ?? _fallbackColors[index % _fallbackColors.length];

  int get _now => widget.nowHour ?? DateTime.now().toUtc().subtract(const Duration(hours: 5)).hour;

  double get _axisMax {
    var peak = 0.0;
    for (final day in widget.data.dayTypes) {
      for (final c in widget.data.conditions) {
        peak = math.max(peak, widget.data.curve(day.id, c.id).fold(0.0, math.max));
      }
    }
    return ((peak / 20).ceil() * 20).clamp(20, 100).toDouble();
  }

  void _toggle(String id) {
    setState(() {
      if (_hidden.contains(id)) {
        _hidden.remove(id);
      } else if (_hidden.length < widget.data.conditions.length - 1) {
        _hidden.add(id); // siempre queda al menos una curva visible
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final day = data.dayTypes[_dayIndex.clamp(0, data.dayTypes.length - 1)];
    final visible = <_Curve>[];
    for (var i = 0; i < data.conditions.length; i++) {
      final c = data.conditions[i];
      if (_hidden.contains(c.id)) continue;
      visible.add(_Curve(c.id, c.label, _colorFor(i, c.id), data.curve(day.id, c.id)));
    }
    final top = visible.reduce((a, b) => a.peak >= b.peak ? a : b);

    return AnalyticsCard(
      icon: Icons.show_chart_rounded,
      title: 'Ocupación por hora',
      subtitle: 'Cómo cambia la afluencia durante el día según el tipo de día y el clima. Toca la curva para ver cada hora.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnalyticsSegmented(
            labels: [for (final d in data.dayTypes) d.label],
            selected: _dayIndex,
            onChanged: (i) => setState(() => _dayIndex = i),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < data.conditions.length; i++)
                _LegendToggle(
                  label: data.conditions[i].label,
                  color: _colorFor(i, data.conditions[i].id),
                  active: !_hidden.contains(data.conditions[i].id),
                  onTap: () => _toggle(data.conditions[i].id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: LineChart(
              _chartData(visible),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.nightlight_round, size: 12, color: AppColors.textLight),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Zona sombreada: noche (el modelo limita la ocupación a 0–1 %)',
                  style: TextStyle(fontSize: 11, color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              children: [
                const TextSpan(text: 'Resumen de la curva con mayor pico: '),
                TextSpan(text: top.label, style: TextStyle(fontWeight: FontWeight.bold, color: top.color)),
                const TextSpan(text: '  (promedio entre 06:00 y 18:00)'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: AnalyticsStat(label: 'Pico', value: formatPct(top.peak), accent: top.color)),
              const SizedBox(width: 8),
              Expanded(child: AnalyticsStat(label: 'Hora pico', value: hourLabel(top.peakHour))),
              const SizedBox(width: 8),
              Expanded(child: AnalyticsStat(label: 'Prom. diurno', value: formatPct(top.daytimeAverage))),
            ],
          ),
        ],
      ),
    );
  }

  LineChartData _chartData(List<_Curve> curves) {
    final now = _now.clamp(0, 23);
    return LineChartData(
      minX: 0,
      maxX: 23,
      minY: 0,
      maxY: _axisMax,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (_) => FlLine(color: AppColors.sandBorder, strokeWidth: 1, dashArray: [4, 4]),
      ),
      borderData: FlBorderData(show: false),
      rangeAnnotations: RangeAnnotations(
        verticalRangeAnnotations: [
          VerticalRangeAnnotation(x1: 0, x2: 5.5, color: AppColors.deepNavy.withValues(alpha: 0.06)),
          VerticalRangeAnnotation(x1: 17.5, x2: 23, color: AppColors.deepNavy.withValues(alpha: 0.06)),
        ],
      ),
      extraLinesData: ExtraLinesData(
        extraLinesOnTop: false,
        verticalLines: [
          VerticalLine(
            x: now.toDouble(),
            color: AppColors.coral,
            strokeWidth: 1.5,
            dashArray: [5, 4],
            label: VerticalLineLabel(
              show: true,
              alignment: now >= 17 ? Alignment.topLeft : Alignment.topRight,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.coral),
              labelResolver: (_) => 'Ahora',
            ),
          ),
        ],
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 20,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              meta: meta,
              space: 6,
              child: Text('${value.toInt()} %', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: 3,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              meta: meta,
              space: 6,
              child: Text('${value.toInt()}h', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ),
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchSpotThreshold: 24,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.deepNavy,
          tooltipBorderRadius: BorderRadius.circular(10),
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          maxContentWidth: 190,
          getTooltipItems: (spots) {
            return [
              for (var i = 0; i < spots.length; i++)
                LineTooltipItem(
                  i == 0 ? '${hourLabel(spots[i].x.toInt())}\n' : '',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  children: [
                    TextSpan(
                      text: '• ${curves[spots[i].barIndex].label}  ${formatPct(spots[i].y)}',
                      style: TextStyle(
                        color: Color.lerp(curves[spots[i].barIndex].color, Colors.white, 0.35),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ];
          },
        ),
        getTouchedSpotIndicator: (bar, indexes) => [
          for (final _ in indexes)
            TouchedSpotIndicatorData(
              const FlLine(color: AppColors.textLight, strokeWidth: 1, dashArray: [3, 3]),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 5,
                  color: barData.color ?? AppColors.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      lineBarsData: [
        for (final c in curves)
          LineChartBarData(
            spots: [for (var h = 0; h < c.values.length; h++) FlSpot(h.toDouble(), c.values[h])],
            isCurved: true,
            curveSmoothness: 0.22,
            preventCurveOverShooting: true,
            color: c.color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.color.withValues(alpha: 0.18), c.color.withValues(alpha: 0.0)],
              ),
            ),
          ),
      ],
    );
  }
}

class _Curve {
  final String id;
  final String label;
  final Color color;
  final List<double> values;
  _Curve(this.id, this.label, this.color, this.values);

  double get peak => values.fold(0.0, math.max);
  int get peakHour => values.indexOf(peak);
  double get daytimeAverage {
    final day = values.sublist(6, 18);
    return day.reduce((a, b) => a + b) / day.length;
  }
}

class _LegendToggle extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _LegendToggle({required this.label, required this.color, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: active,
      label: 'Mostrar u ocultar $label',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? color : AppColors.sandBorder, width: active ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: active ? color : AppColors.textLight, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.deepNavy : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
