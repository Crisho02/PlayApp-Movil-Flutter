import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/sales_charts_model.dart';
import 'charts_common.dart';
import 'kpi_section.dart';

/// Gráfica 2: tendencia de ventas en el tiempo, con el periodo anterior superpuesto.
class SalesTrendCard extends StatefulWidget {
  final SalesChartsData data;
  final TrendMetric metric;
  final ValueChanged<TrendMetric> onMetric;

  /// Granularidad pedida en el filtro (auto | day | week | month).
  final String granularity;
  final ValueChanged<String> onGranularity;

  const SalesTrendCard({
    super.key,
    required this.data,
    required this.metric,
    required this.onMetric,
    required this.granularity,
    required this.onGranularity,
  });

  @override
  State<SalesTrendCard> createState() => _SalesTrendCardState();
}

class _SalesTrendCardState extends State<SalesTrendCard> {
  static const _granularities = ['auto', 'day', 'week', 'month'];
  bool _compare = true;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final m = widget.metric;
    final values = m.series(d.trend);
    final prev = m.previous(d.trend);
    final showPrev = _compare && prev != null && d.hasPrevious;
    final n = values.length;
    final total = values.fold<double>(0, (a, b) => a + b);
    final avg = n == 0 ? 0.0 : total / n;
    var best = 0;
    for (var i = 1; i < n; i++) {
      if (values[i] > values[best]) best = i;
    }

    return AnalyticsCard(
      icon: Icons.timeline_rounded,
      title: 'Tendencia de ventas',
      subtitle: 'Evolución en el periodo elegido. La línea punteada es el periodo anterior de igual duración.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnalyticsSegmented(
            labels: const ['Ingresos', 'Pedidos', 'Unidades', 'Ticket'],
            selected: TrendMetric.values.indexOf(m),
            onChanged: (i) => widget.onMetric(TrendMetric.values[i]),
          ),
          const SizedBox(height: 10),
          AnalyticsSegmented(
            labels: const ['Auto', 'Día', 'Semana', 'Mes'],
            selected: math.max(0, _granularities.indexOf(widget.granularity)),
            onChanged: (i) => widget.onGranularity(_granularities[i]),
          ),
          if (d.hasPrevious) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Comparar con el periodo anterior',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMain, fontWeight: FontWeight.w500),
                  ),
                ),
                Switch.adaptive(
                  value: _compare,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _compare = v),
                ),
              ],
            ),
          ] else
            const SizedBox(height: 12),
          if (d.isEmpty)
            const ChartEmpty()
          else ...[
            SizedBox(height: 240, child: LineChart(_chart(values, showPrev ? prev : null, avg), duration: const Duration(milliseconds: 350))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _Legend(color: AppColors.primary, label: '${m.label} · actual'),
                if (showPrev) const _Legend(color: AppColors.textLight, label: 'Periodo anterior', dashed: true),
                const _Legend(color: AppColors.warning, label: 'Promedio', dashed: true),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: AnalyticsStat(label: m == TrendMetric.ticket ? 'Ticket del periodo' : 'Total', value: m == TrendMetric.ticket ? m.format(m.kpi(d).actual) : m.format(total))),
                const SizedBox(width: 8),
                Expanded(child: AnalyticsStat(label: 'Promedio', value: m.format(avg, compact: true))),
                const SizedBox(width: 8),
                Expanded(
                  child: AnalyticsStat(
                    label: 'Mejor: ${n == 0 ? '—' : bucketLabel(d.trend.labels[best], d.granularidad)}',
                    value: n == 0 ? '—' : m.format(values[best], compact: true),
                    accent: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  LineChartData _chart(List<double> values, List<double?>? prev, double avg) {
    final m = widget.metric;
    final d = widget.data;
    final n = values.length;
    var maxV = values.fold<double>(0, math.max);
    if (prev != null) {
      for (final v in prev) {
        if (v != null && v > maxV) maxV = v;
      }
    }
    final maxY = maxV <= 0 ? 1.0 : maxV * 1.18;
    final labelEvery = math.max(1, (n / 4).ceil());

    return LineChartData(
      minX: 0,
      maxX: math.max(1, n - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.sandBorder, strokeWidth: 1, dashArray: [4, 4]),
      ),
      borderData: FlBorderData(show: false),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          if (avg > 0)
            HorizontalLine(
              y: avg,
              color: AppColors.warning.withValues(alpha: 0.9),
              strokeWidth: 1.2,
              dashArray: [6, 4],
            ),
        ],
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            interval: maxY / 4,
            getTitlesWidget: (v, meta) => SideTitleWidget(
              meta: meta,
              space: 4,
              child: Text(m.format(v, compact: true), style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: 1,
            getTitlesWidget: (v, meta) {
              final i = v.round();
              if ((v - i).abs() > 0.01 || i < 0 || i >= n || i % labelEvery != 0) return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text(bucketLabel(d.trend.labels[i], d.granularidad), style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchSpotThreshold: 30,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.deepNavy,
          tooltipBorderRadius: BorderRadius.circular(10),
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          maxContentWidth: 210,
          getTooltipItems: (spots) {
            final sorted = [...spots]..sort((a, b) => a.barIndex.compareTo(b.barIndex));
            return [
              for (final s in spots)
                s == sorted.first
                    ? LineTooltipItem(
                        '${bucketLabel(d.trend.labels[s.x.round().clamp(0, n - 1)], d.granularidad, long: true)}\n',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        children: [
                          for (final t in sorted)
                            TextSpan(
                              text: '${t.barIndex == 0 ? 'Actual' : 'Anterior'}: ${m.format(t.y)}\n',
                              style: TextStyle(
                                color: t.barIndex == 0 ? const Color(0xFF7DD3FC) : const Color(0xFFCBD5E1),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      )
                    : null,
            ];
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [for (var i = 0; i < n; i++) FlSpot(i.toDouble(), values[i])],
          isCurved: n > 2,
          preventCurveOverShooting: true,
          curveSmoothness: 0.2,
          color: AppColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: n <= 12),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary.withValues(alpha: 0.25), AppColors.primary.withValues(alpha: 0)],
            ),
          ),
        ),
        if (prev != null)
          LineChartBarData(
            spots: [
              for (var i = 0; i < prev.length && i < n; i++)
                if (prev[i] != null) FlSpot(i.toDouble(), prev[i]!),
            ],
            isCurved: n > 2,
            preventCurveOverShooting: true,
            curveSmoothness: 0.2,
            color: AppColors.textLight,
            barWidth: 2,
            dashArray: [6, 5],
            dotData: const FlDotData(show: false),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _Legend({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 3,
          child: dashed
              ? Row(children: [
                  Expanded(child: Container(height: 3, color: color)),
                  const SizedBox(width: 3),
                  Expanded(child: Container(height: 3, color: color)),
                ])
              : ColoredBox(color: color),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
