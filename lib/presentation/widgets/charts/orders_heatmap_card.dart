import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/sales_charts_model.dart';
import 'charts_common.dart';

/// Gráfica 6: cuándo se compra. Mapa de calor día de la semana x hora con los pedidos reales.
class OrdersHeatmapCard extends StatefulWidget {
  final SalesChartsData data;
  const OrdersHeatmapCard({super.key, required this.data});

  @override
  State<OrdersHeatmapCard> createState() => _OrdersHeatmapCardState();
}

class _OrdersHeatmapCardState extends State<OrdersHeatmapCard> {
  bool _money = false;
  bool _fullDay = false;
  int? _row;
  int? _col;

  @override
  void didUpdateWidget(covariant OrdersHeatmapCard old) {
    super.didUpdateWidget(old);
    if (!identical(old.data, widget.data)) {
      _row = null;
      _col = null;
    }
  }

  List<List<double>> get _grid => _money ? widget.data.heatmapIngresos : widget.data.heatmapPedidos;

  /// Rango de horas visible: 24 h, o solo las horas con ventas (mínimo 8 columnas).
  (int, int) _hours(List<List<double>> g) {
    if (_fullDay) return (0, 23);
    var minH = 24, maxH = -1;
    for (final row in g) {
      for (var h = 0; h < 24; h++) {
        if (row[h] > 0) {
          minH = math.min(minH, h);
          maxH = math.max(maxH, h);
        }
      }
    }
    if (maxH < 0) return (6, 21);
    while (maxH - minH + 1 < 8) {
      if (minH > 0) minH--;
      if (maxH - minH + 1 < 8 && maxH < 23) maxH++;
    }
    return (minH, maxH);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final g = _grid;
    final (first, last) = _hours(g);
    var maxV = 0.0, bestR = 0, bestC = first;
    final dayTotals = List<double>.filled(7, 0);
    final hourTotals = List<double>.filled(24, 0);
    for (var r = 0; r < 7; r++) {
      for (var h = 0; h < 24; h++) {
        dayTotals[r] += g[r][h];
        hourTotals[h] += g[r][h];
        if (g[r][h] > maxV) {
          maxV = g[r][h];
          bestR = r;
          bestC = h;
        }
      }
    }
    var bestDay = 0, bestHour = 0;
    for (var i = 1; i < 7; i++) {
      if (dayTotals[i] > dayTotals[bestDay]) bestDay = i;
    }
    for (var i = 1; i < 24; i++) {
      if (hourTotals[i] > hourTotals[bestHour]) bestHour = i;
    }
    var row = _row ?? bestR;
    var col = _col ?? bestC;
    if (col < first || col > last) col = bestC.clamp(first, last);
    row = row.clamp(0, 6);
    final value = g[row][col];
    String fmt(double v) => _money ? formatMoney(v) : '${formatNumber(v)} ${v == 1 ? 'pedido' : 'pedidos'}';

    return AnalyticsCard(
      icon: Icons.grid_on_rounded,
      title: '¿Cuándo se compra?',
      subtitle: 'Pedidos por día de la semana y hora. Toca una celda o desliza sobre una fila.',
      child: d.isEmpty
          ? const ChartEmpty()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnalyticsSegmented(
                  labels: const ['Pedidos', 'Ingresos'],
                  selected: _money ? 1 : 0,
                  onChanged: (i) => setState(() => _money = i == 1),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 230,
                    child: AnalyticsSegmented(
                      labels: const ['Horas con ventas', '24 h'],
                      selected: _fullDay ? 1 : 0,
                      onChanged: (i) => setState(() => _fullDay = i == 1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _HeatGrid(
                  grid: g,
                  first: first,
                  last: last,
                  max: maxV,
                  row: row,
                  col: col,
                  onSelect: (r, c) => setState(() {
                    _row = r;
                    _col = c;
                  }),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('0', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(gradient: heatGradient(), borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_money ? formatMoneyCompact(maxV) : formatNumber(maxV), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sandBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: heatColor(value, max: maxV).withValues(alpha: 0.8), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weekdayLong[row]} · ${hourLabel(col)} – ${hourLabel((col + 1) % 24)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
                      ),
                      const SizedBox(height: 2),
                      Text(fmt(value), style: const TextStyle(fontSize: 13, color: AppColors.textMain)),
                      if (row == bestR && col == bestC && maxV > 0)
                        const Text('Franja más fuerte del periodo', style: TextStyle(fontSize: 11.5, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: AnalyticsStat(label: 'Día más fuerte', value: '${weekdayLong[bestDay]} · ${_money ? formatMoneyCompact(dayTotals[bestDay]) : formatNumber(dayTotals[bestDay])}')),
                    const SizedBox(width: 8),
                    Expanded(child: AnalyticsStat(label: 'Hora pico', value: '${hourLabel(bestHour)} · ${_money ? formatMoneyCompact(hourTotals[bestHour]) : formatNumber(hourTotals[bestHour])}')),
                  ],
                ),
              ],
            ),
    );
  }
}

class _HeatGrid extends StatelessWidget {
  final List<List<double>> grid;
  final int first;
  final int last;
  final double max;
  final int row;
  final int col;
  final void Function(int r, int c) onSelect;

  static const double labelW = 34;
  static const double headerH = 18;
  static const double rowH = 30;

  const _HeatGrid({required this.grid, required this.first, required this.last, required this.max, required this.row, required this.col, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cols = last - first + 1;
    return LayoutBuilder(
      builder: (context, c) {
        final cellW = (c.maxWidth - labelW) / cols;
        void pick(Offset p, {bool keepRow = false}) {
          final ci = ((p.dx - labelW) / cellW).floor();
          final ri = keepRow ? row : ((p.dy - headerH) / rowH).floor();
          if (ci < 0 || ci >= cols || ri < 0 || ri > 6) return;
          if (ri != row || ci + first != col) onSelect(ri, ci + first);
        }

        return Semantics(
          label: 'Mapa de calor de pedidos por día y hora',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => pick(d.localPosition),
            onHorizontalDragStart: (d) => pick(d.localPosition),
            onHorizontalDragUpdate: (d) => pick(d.localPosition, keepRow: true),
            child: TweenAnimationBuilder<double>(
              key: ValueKey('$first-$last-${grid.hashCode}'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => CustomPaint(
                size: Size(c.maxWidth, headerH + rowH * 7),
                painter: _HeatPainter(grid: grid, first: first, last: last, max: max, row: row, col: col, progress: t, base: painterTextStyle(context)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeatPainter extends CustomPainter {
  final List<List<double>> grid;
  final int first;
  final int last;
  final double max;
  final int row;
  final int col;
  final double progress;
  final TextStyle base;

  _HeatPainter({required this.grid, required this.first, required this.last, required this.max, required this.row, required this.col, required this.progress, required this.base});

  void _text(Canvas canvas, String s, Offset center, {bool bold = false, Color color = AppColors.textMuted, double size = 10}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: base.copyWith(fontSize: size, color: color, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const lw = _HeatGrid.labelW, hh = _HeatGrid.headerH, rh = _HeatGrid.rowH, gap = 1.5;
    final cols = last - first + 1;
    final cw = (size.width - lw) / cols;
    final step = cols > 16 ? 3 : (cols > 10 ? 2 : 1);
    for (var c = 0; c < cols; c++) {
      final h = first + c;
      if (h % step != 0 && h != col) continue;
      _text(canvas, '$h', Offset(lw + c * cw + cw / 2, hh / 2), bold: h == col, color: h == col ? AppColors.primaryDark : AppColors.textMuted);
    }
    for (var r = 0; r < 7; r++) {
      _text(canvas, weekdayShort[r], Offset(lw / 2 - 2, hh + r * rh + rh / 2), bold: r == row, color: r == row ? AppColors.primaryDark : AppColors.textMuted, size: 11);
      for (var c = 0; c < cols; c++) {
        final v = grid[r][first + c];
        final rect = Rect.fromLTWH(lw + c * cw + gap / 2, hh + r * rh + gap / 2, cw - gap, rh - gap);
        final color = v <= 0 ? const Color(0xFFF1F5F9) : heatColor(v * progress, max: max);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), Paint()..color = color);
      }
    }
    if (col >= first && col <= last) {
      final c = col - first;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(lw, hh + row * rh, size.width - lw, rh), const Radius.circular(4)),
        Paint()
          ..color = AppColors.deepNavy.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(lw + c * cw, hh + row * rh, cw, rh).deflate(0.5), const Radius.circular(4)),
        Paint()
          ..color = AppColors.deepNavy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) =>
      old.progress != progress || old.row != row || old.col != col || old.first != first || old.last != last || old.max != max ||
      !identical(old.grid, grid) || old.base != base;
}
