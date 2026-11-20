import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/sales_charts_model.dart';
import 'charts_common.dart';

/// Gráfica 4: comparador de hasta 3 productos (líneas en el tiempo, radar y tabla).
class ProductComparatorCard extends StatefulWidget {
  final SalesChartsData data;
  const ProductComparatorCard({super.key, required this.data});

  @override
  State<ProductComparatorCard> createState() => _ProductComparatorCardState();
}

class _Axis {
  final String label;
  final double? Function(ChartProduct) value;
  final String Function(double) format;
  const _Axis(this.label, this.value, this.format);
}

class _ProductComparatorCardState extends State<ProductComparatorCard> {
  static const _max = 3;
  final List<String> _selected = [];
  bool _money = true;

  static final List<_Axis> _axes = [
    _Axis('Unidades', (p) => p.unidades, formatNumber),
    _Axis('Ingresos', (p) => p.ingresos, formatMoney),
    _Axis('Ticket', (p) => p.ticketPromedio, formatMoney),
    _Axis('Frecuencia', (p) => p.frecuenciaPct, formatPct),
    _Axis('Rotación', (p) => p.rotacionPct, formatPct),
  ];

  @override
  void didUpdateWidget(covariant ProductComparatorCard old) {
    super.didUpdateWidget(old);
    // Si cambian los filtros, se descartan selecciones que ya no existen.
    final ids = widget.data.products.map((p) => p.id).toSet();
    _selected.removeWhere((id) => !ids.contains(id));
  }

  List<ChartProduct> get _chosen {
    if (_selected.isEmpty) {
      // Por defecto: los dos productos con más ingresos.
      final top = widget.data.products.where((p) => p.ingresos > 0).take(2).map((p) => p.id);
      _selected.addAll(top.isEmpty ? widget.data.products.take(2).map((p) => p.id) : top);
    }
    final byId = {for (final p in widget.data.products) p.id: p};
    return [for (final id in _selected) if (byId[id] != null) byId[id]!];
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        if (_selected.length > 1) _selected.remove(id);
      } else if (_selected.length < _max) {
        _selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    if (d.products.length < 2) {
      return const AnalyticsCard(
        icon: Icons.compare_arrows_rounded,
        title: 'Comparador de productos',
        subtitle: 'Compara hasta 3 productos entre sí.',
        child: ChartEmpty(message: 'Se necesitan al menos 2 productos para comparar.'),
      );
    }
    final chosen = _chosen;

    return AnalyticsCard(
      icon: Icons.compare_arrows_rounded,
      title: 'Comparador de productos',
      subtitle: 'Elige hasta 3 productos para comparar su evolución y su desempeño.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in d.products)
                _ProductChip(
                  product: p,
                  color: _selected.contains(p.id) ? seriesPalette[_selected.indexOf(p.id) % seriesPalette.length] : null,
                  enabled: _selected.contains(p.id) || _selected.length < _max,
                  onTap: () => _toggle(p.id),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${chosen.length} de $_max seleccionados',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          AnalyticsSegmented(
            labels: const ['Ingresos en el tiempo', 'Unidades en el tiempo'],
            selected: _money ? 0 : 1,
            onChanged: (i) => setState(() => _money = i == 0),
          ),
          const SizedBox(height: 12),
          if (d.isEmpty)
            const ChartEmpty()
          else
            SizedBox(height: 210, child: LineChart(_lines(chosen), duration: const Duration(milliseconds: 350))),
          const SizedBox(height: 18),
          const Text('Desempeño relativo', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.deepNavy)),
          const SizedBox(height: 2),
          const Text(
            'Cada eje va de 0 al mejor valor entre todos los productos del periodo.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          if (chosen.length >= 2 && !d.isEmpty)
            SizedBox(height: 260, child: RadarChart(_radar(chosen), duration: const Duration(milliseconds: 350)))
          else
            const ChartEmpty(message: 'Selecciona al menos 2 productos con ventas para ver el radar.'),
          const SizedBox(height: 10),
          _table(chosen),
        ],
      ),
    );
  }

  LineChartData _lines(List<ChartProduct> chosen) {
    final d = widget.data;
    final n = d.trend.labels.length;
    var maxV = 0.0;
    for (final p in chosen) {
      for (final v in (_money ? p.serieIngresos : p.serieUnidades)) {
        maxV = math.max(maxV, v);
      }
    }
    final maxY = maxV <= 0 ? 1.0 : maxV * 1.18;
    final every = math.max(1, (n / 4).ceil());
    return LineChartData(
      minX: 0,
      maxX: math.max(1, n - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      clipData: const FlClipData.all(),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.sandBorder, strokeWidth: 1, dashArray: [4, 4]),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 48,
            interval: maxY / 4,
            getTitlesWidget: (v, meta) => SideTitleWidget(
              meta: meta,
              space: 4,
              child: Text(_money ? formatMoneyCompact(v) : formatNumber(v), style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: 1,
            getTitlesWidget: (v, meta) {
              final i = v.round();
              if ((v - i).abs() > 0.01 || i < 0 || i >= n || i % every != 0) return const SizedBox.shrink();
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
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          maxContentWidth: 220,
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
                              text: '${chosen[t.barIndex].nombre}: ${_money ? formatMoney(t.y) : '${formatNumber(t.y)} uds.'}\n',
                              style: TextStyle(
                                color: Color.lerp(seriesPalette[t.barIndex % seriesPalette.length], Colors.white, 0.45),
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
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
        for (var k = 0; k < chosen.length; k++)
          LineChartBarData(
            spots: [
              for (var i = 0; i < n; i++) FlSpot(i.toDouble(), (_money ? chosen[k].serieIngresos : chosen[k].serieUnidades)[i]),
            ],
            isCurved: n > 2,
            preventCurveOverShooting: true,
            curveSmoothness: 0.2,
            color: seriesPalette[k % seriesPalette.length],
            barWidth: 2.6,
            dotData: FlDotData(show: n <= 12),
          ),
      ],
    );
  }

  RadarChartData _radar(List<ChartProduct> chosen) {
    final all = widget.data.products;
    final maxima = [
      for (final a in _axes) all.map((p) => a.value(p) ?? 0).fold<double>(0, math.max),
    ];
    return RadarChartData(
      radarShape: RadarShape.polygon,
      tickCount: 4,
      ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 1),
      tickBorderData: const BorderSide(color: AppColors.sandBorder, width: 1),
      gridBorderData: const BorderSide(color: AppColors.sandBorder, width: 1),
      radarBorderData: const BorderSide(color: AppColors.sandBorder, width: 1.5),
      titlePositionPercentageOffset: 0.22,
      titleTextStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.deepNavy),
      getTitle: (i, angle) => RadarChartTitle(text: _axes[i].label),
      radarTouchData: RadarTouchData(enabled: false),
      dataSets: [
        for (var k = 0; k < chosen.length; k++)
          RadarDataSet(
            fillColor: seriesPalette[k % seriesPalette.length].withValues(alpha: 0.18),
            borderColor: seriesPalette[k % seriesPalette.length],
            borderWidth: 2,
            entryRadius: 3,
            dataEntries: [
              for (var a = 0; a < _axes.length; a++)
                RadarEntry(value: maxima[a] <= 0 ? 0 : ((_axes[a].value(chosen[k]) ?? 0) / maxima[a] * 100)),
            ],
          ),
        // Conjunto invisible en 100: fija la escala de 0 a 100 en todos los ejes.
        RadarDataSet(
          fillColor: Colors.transparent,
          borderColor: Colors.transparent,
          borderWidth: 0,
          entryRadius: 0,
          dataEntries: [for (var a = 0; a < _axes.length; a++) const RadarEntry(value: 100)],
        ),
      ],
    );
  }

  Widget _table(List<ChartProduct> chosen) {
    if (chosen.isEmpty) return const SizedBox.shrink();
    TextStyle head(Color c) => TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: c);
    return Container(
      decoration: BoxDecoration(color: AppColors.sandBackground, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(10),
      child: Table(
        columnWidths: {0: const FlexColumnWidth(1.1), for (var k = 0; k < chosen.length; k++) k + 1: const FlexColumnWidth(1)},
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(children: [
            const SizedBox.shrink(),
            for (var k = 0; k < chosen.length; k++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  chosen[k].nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: head(seriesPalette[k % seriesPalette.length]),
                ),
              ),
          ]),
          for (final a in _axes)
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(a.label, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              ),
              for (var k = 0; k < chosen.length; k++) _cell(a, chosen, k),
            ]),
        ],
      ),
    );
  }

  Widget _cell(_Axis a, List<ChartProduct> chosen, int k) {
    final v = a.value(chosen[k]);
    final best = chosen.map((p) => a.value(p) ?? -1).fold<double>(-1, math.max);
    final winner = v != null && v > 0 && v == best;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (winner) const Icon(Icons.emoji_events_rounded, size: 13, color: AppColors.warning),
            if (winner) const SizedBox(width: 2),
            Text(
              v == null ? '—' : a.format(v),
              style: TextStyle(
                fontSize: 12,
                fontWeight: winner ? FontWeight.bold : FontWeight.w500,
                color: winner ? AppColors.deepNavy : AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductChip extends StatelessWidget {
  final ChartProduct product;
  final Color? color;
  final bool enabled;
  final VoidCallback onTap;
  const _ProductChip({required this.product, required this.color, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = color != null;
    return Semantics(
      button: true,
      selected: selected,
      label: product.nombre,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.4,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 34),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? color!.withValues(alpha: 0.12) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? color! : AppColors.sandBorder, width: selected ? 1.6 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(Icons.check_rounded, size: 14, color: color),
                  const SizedBox(width: 4),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    product.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? AppColors.deepNavy : AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
