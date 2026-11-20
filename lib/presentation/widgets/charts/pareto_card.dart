import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/sales_charts_model.dart';
import 'charts_common.dart';

/// Un elemento del diagrama de Pareto (producto o el grupo "Otros").
class ParetoItem {
  final String nombre;
  final double ingresos;
  final double sharePct;
  final double cumulativePct;
  final int productos; // 1, o los productos agrupados en "Otros"
  const ParetoItem(this.nombre, this.ingresos, this.sharePct, this.cumulativePct, this.productos);
}

/// Construye el Pareto por ingresos. Con más de [maxBars] productos, el resto se agrupa en "Otros".
List<ParetoItem> buildPareto(List<ChartProduct> products, {int maxBars = 15}) {
  final sorted = [...products]..sort((a, b) => b.ingresos.compareTo(a.ingresos));
  final total = sorted.fold<double>(0, (a, p) => a + p.ingresos);
  if (total <= 0) return const [];
  final items = <ParetoItem>[];
  var acc = 0.0;
  for (var i = 0; i < sorted.length; i++) {
    if (i == maxBars - 1 && sorted.length > maxBars) {
      final rest = sorted.sublist(i);
      final restTotal = rest.fold<double>(0, (a, p) => a + p.ingresos);
      acc += restTotal;
      items.add(ParetoItem('Otros (${rest.length})', restTotal, restTotal * 100 / total, math.min(100, acc * 100 / total), rest.length));
      break;
    }
    acc += sorted[i].ingresos;
    items.add(ParetoItem(sorted[i].nombre, sorted[i].ingresos, sorted[i].ingresos * 100 / total, math.min(100, acc * 100 / total), 1));
  }
  return items;
}

/// Cuántos productos (en orden) alcanzan el 80 % de los ingresos.
int productsFor80(List<ChartProduct> products) {
  final sorted = [...products]..sort((a, b) => b.ingresos.compareTo(a.ingresos));
  final total = sorted.fold<double>(0, (a, p) => a + p.ingresos);
  if (total <= 0) return 0;
  var acc = 0.0;
  for (var i = 0; i < sorted.length; i++) {
    acc += sorted[i].ingresos;
    if (acc >= total * 0.8 - 1e-6) return i + 1;
  }
  return sorted.length;
}

/// Gráfica 5: diagrama de Pareto (barras de ingresos + línea acumulada + umbral del 80 %).
class ParetoCard extends StatefulWidget {
  final SalesChartsData data;
  const ParetoCard({super.key, required this.data});

  @override
  State<ParetoCard> createState() => _ParetoCardState();
}

class _ParetoCardState extends State<ParetoCard> {
  int? _selected;

  @override
  void didUpdateWidget(covariant ParetoCard old) {
    super.didUpdateWidget(old);
    if (!identical(old.data, widget.data)) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.data.products;
    final items = buildPareto(products);
    final conVentas = products.where((p) => p.ingresos > 0).length;
    final k80 = productsFor80(products);
    final sel = items.isEmpty ? null : (_selected ?? 0).clamp(0, items.length - 1);

    return AnalyticsCard(
      icon: Icons.stacked_bar_chart_rounded,
      title: 'Pareto de ingresos (80/20)',
      subtitle: 'Qué productos concentran la mayor parte de los ingresos. Toca o desliza sobre las barras.',
      child: items.isEmpty
          ? const ChartEmpty()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 13, color: AppColors.textMain, height: 1.35),
                      children: [
                        TextSpan(
                          text: '$k80 de ${products.length} productos',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                        TextSpan(
                          text: ' (${formatPct(products.isEmpty ? 0 : k80 * 100 / products.length)}) generan el 80 % de los ingresos. '
                              '$conVentas tuvieron ventas en el periodo.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _ParetoChart(items: items, selected: sel, onSelect: (i) => setState(() => _selected = i)),
                const SizedBox(height: 8),
                const Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _Key(color: AppColors.primary, label: 'Hasta el 80 %'),
                    _Key(color: Color(0xFFBAE6FD), label: 'Resto'),
                    _Key(color: AppColors.coral, label: '% acumulado', line: true),
                  ],
                ),
                if (sel != null) ...[
                  const SizedBox(height: 12),
                  _Detail(item: items[sel], rank: sel + 1),
                ],
              ],
            ),
    );
  }
}

class _ParetoChart extends StatelessWidget {
  final List<ParetoItem> items;
  final int? selected;
  final ValueChanged<int> onSelect;

  static const double leftAxis = 48;
  static const double rightAxis = 34;
  static const double bottomAxis = 20;
  static const double height = 220;

  const _ParetoChart({required this.items, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final plotW = c.maxWidth - leftAxis - rightAxis;
        void pick(Offset p) {
          final i = ((p.dx - leftAxis) / (plotW / items.length)).floor();
          if (i >= 0 && i < items.length && i != selected) onSelect(i);
        }

        return Semantics(
          label: 'Diagrama de Pareto de ingresos por producto',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => pick(d.localPosition),
            onHorizontalDragStart: (d) => pick(d.localPosition),
            onHorizontalDragUpdate: (d) => pick(d.localPosition),
            child: TweenAnimationBuilder<double>(
              key: ValueKey(items.length + items.first.ingresos),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => CustomPaint(
                size: Size(c.maxWidth, height),
                painter: _ParetoPainter(items: items, selected: selected, progress: t, base: painterTextStyle(context)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ParetoPainter extends CustomPainter {
  final List<ParetoItem> items;
  final int? selected;
  final double progress;
  final TextStyle base;
  _ParetoPainter({required this.items, required this.selected, required this.progress, required this.base});

  void _text(Canvas canvas, String s, Offset at, {TextAlign align = TextAlign.left, Color color = AppColors.textMuted, double size = 9.5, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: base.copyWith(fontSize: size, color: color, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final dx = switch (align) {
      TextAlign.right => at.dx - tp.width,
      TextAlign.center => at.dx - tp.width / 2,
      _ => at.dx,
    };
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const l = _ParetoChart.leftAxis;
    const r = _ParetoChart.rightAxis;
    const b = _ParetoChart.bottomAxis;
    const top = 8.0;
    final plot = Rect.fromLTRB(l, top, size.width - r, size.height - b);
    final maxV = items.map((e) => e.ingresos).fold<double>(0, math.max) * 1.1;
    final grid = Paint()
      ..color = AppColors.sandBorder
      ..strokeWidth = 1;

    // Rejilla y eje izquierdo (ingresos)
    for (var i = 0; i <= 4; i++) {
      final y = plot.bottom - plot.height * i / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      _text(canvas, formatMoneyCompact(maxV * i / 4), Offset(plot.left - 4, y), align: TextAlign.right);
    }
    // Eje derecho (% acumulado)
    for (final p in [0, 50, 100]) {
      final y = plot.bottom - plot.height * p / 100;
      _text(canvas, '$p %', Offset(plot.right + 4, y), color: AppColors.coral);
    }

    final slot = plot.width / items.length;
    final barW = math.min(26.0, slot * 0.68);
    final points = <Offset>[];
    var crossed80 = false;
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      final cx = plot.left + slot * i + slot / 2;
      final h = maxV <= 0 ? 0.0 : plot.height * (it.ingresos / maxV) * progress;
      final inCore = !crossed80;
      if (it.cumulativePct >= 80 - 1e-6) crossed80 = true;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - barW / 2, plot.bottom - h, barW, h),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      final isSel = i == selected;
      canvas.drawRRect(rect, Paint()..color = inCore ? (isSel ? AppColors.primaryDark : AppColors.primary) : (isSel ? const Color(0xFF7DD3FC) : const Color(0xFFBAE6FD)));
      points.add(Offset(cx, plot.bottom - plot.height * (it.cumulativePct / 100) * progress));
      final every = items.length > 10 ? 2 : 1;
      if (i % every == 0 || isSel) {
        _text(canvas, '${i + 1}', Offset(cx, size.height - b / 2), align: TextAlign.center, bold: isSel, color: isSel ? AppColors.primaryDark : AppColors.textMuted);
      }
    }

    // Umbral del 80 %
    final y80 = plot.bottom - plot.height * 0.8;
    final dash = Paint()
      ..color = AppColors.coral.withValues(alpha: 0.7)
      ..strokeWidth = 1.2;
    for (var x = plot.left; x < plot.right; x += 9) {
      canvas.drawLine(Offset(x, y80), Offset(math.min(x + 5, plot.right), y80), dash);
    }
    _text(canvas, '80 %', Offset(plot.right - 2, y80 - 8), align: TextAlign.right, color: AppColors.coral, bold: true);

    // Línea acumulada
    if (points.isNotEmpty) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.coral
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round,
      );
      for (var i = 0; i < points.length; i++) {
        canvas.drawCircle(points[i], i == selected ? 5 : 3, Paint()..color = Colors.white);
        canvas.drawCircle(points[i], i == selected ? 4 : 2.2, Paint()..color = AppColors.coral);
      }
    }

    // Selección
    if (selected != null && selected! < items.length) {
      final cx = plot.left + slot * selected! + slot / 2;
      canvas.drawLine(
        Offset(cx, plot.top),
        Offset(cx, plot.bottom),
        Paint()
          ..color = AppColors.deepNavy.withValues(alpha: 0.25)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_ParetoPainter old) =>
      old.progress != progress || old.selected != selected || !identical(old.items, items) || old.base != base;
}

class _Detail extends StatelessWidget {
  final ParetoItem item;
  final int rank;
  const _Detail({required this.item, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sandBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#$rank · ${item.nombre}',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: AnalyticsStat(label: 'Ingresos', value: formatMoney(item.ingresos))),
              const SizedBox(width: 8),
              Expanded(child: AnalyticsStat(label: 'Participación', value: formatPct(item.sharePct), accent: AppColors.primary)),
              const SizedBox(width: 8),
              Expanded(child: AnalyticsStat(label: 'Acumulado', value: formatPct(item.cumulativePct), accent: AppColors.coral)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final Color color;
  final String label;
  final bool line;
  const _Key({required this.color, required this.label, this.line = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line
            ? Container(width: 16, height: 3, color: color)
            : Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
