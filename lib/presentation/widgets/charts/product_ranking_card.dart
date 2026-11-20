import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/sales_charts_model.dart';
import 'charts_common.dart';

enum RankMetric { unidades, ingresos, pedidos }

extension RankMetricInfo on RankMetric {
  double of(ChartProduct p) => switch (this) {
        RankMetric.unidades => p.unidades,
        RankMetric.ingresos => p.ingresos,
        RankMetric.pedidos => p.pedidos.toDouble(),
      };

  String format(double v) => this == RankMetric.ingresos ? formatMoney(v) : formatNumber(v);

  String get unit => switch (this) {
        RankMetric.unidades => 'uds.',
        RankMetric.ingresos => '',
        RankMetric.pedidos => 'pedidos',
      };
}

/// Gráfica 3: ranking de productos más y menos vendidos (incluye los que no tienen ventas).
class ProductRankingCard extends StatefulWidget {
  final SalesChartsData data;
  const ProductRankingCard({super.key, required this.data});

  @override
  State<ProductRankingCard> createState() => _ProductRankingCardState();
}

class _ProductRankingCardState extends State<ProductRankingCard> {
  static const _collapsed = 5;
  bool _mostSold = true;
  RankMetric _metric = RankMetric.unidades;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final products = [...widget.data.products];
    products.sort((a, b) {
      final c = _metric.of(a).compareTo(_metric.of(b));
      if (c != 0) return _mostSold ? -c : c;
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
    final maxV = products.fold<double>(0, (a, p) => math.max(a, _metric.of(p)));
    final visible = _expanded ? products : products.take(_collapsed).toList();
    final sinVentas = products.where((p) => p.unidades == 0).length;

    return AnalyticsCard(
      icon: Icons.leaderboard_rounded,
      title: 'Productos más y menos vendidos',
      subtitle: 'Ranking del periodo. Toca un producto para ver su ficha completa.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnalyticsSegmented(
            labels: const ['Más vendidos', 'Menos vendidos'],
            selected: _mostSold ? 0 : 1,
            onChanged: (i) => setState(() => _mostSold = i == 0),
          ),
          const SizedBox(height: 10),
          AnalyticsSegmented(
            labels: const ['Unidades', 'Ingresos', 'Pedidos'],
            selected: _metric.index,
            onChanged: (i) => setState(() => _metric = RankMetric.values[i]),
          ),
          const SizedBox(height: 14),
          if (products.isEmpty)
            const ChartEmpty(message: 'No hay productos registrados para este filtro.')
          else ...[
            for (var i = 0; i < visible.length; i++)
              _RankRow(
                rank: i + 1,
                product: visible[i],
                metric: _metric,
                fraction: maxV <= 0 ? 0 : _metric.of(visible[i]) / maxV,
                onTap: () => showProductDetail(context, widget.data, visible[i]),
              ),
            if (products.length > _collapsed)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18),
                  label: Text(_expanded ? 'Ver menos' : 'Ver todos (${products.length})'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark, minimumSize: const Size(48, 40)),
                ),
              ),
            if (sinVentas > 0) ...[
              const SizedBox(height: 4),
              Text(
                sinVentas == 1 ? '1 producto no tuvo ventas en este periodo.' : '$sinVentas productos no tuvieron ventas en este periodo.',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final ChartProduct product;
  final RankMetric metric;
  final double fraction;
  final VoidCallback onTap;

  const _RankRow({required this.rank, required this.product, required this.metric, required this.fraction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final v = metric.of(product);
    final color = categoryColor(product.categoria);
    return Semantics(
      button: true,
      label: '$rank. ${product.nombre}: ${metric.format(v)} ${metric.unit}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank <= 3 ? color.withValues(alpha: 0.15) : AppColors.sandBackground,
                  shape: BoxShape.circle,
                ),
                child: Text('$rank', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: rank <= 3 ? color : AppColors.textMuted)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.nombre,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepNavy),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Ancho máximo fijo: el nombre usa el resto y la cifra queda alineada a la derecha.
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              v == 0 ? 'Sin ventas' : '${metric.format(v)} ${metric.unit}'.trim(),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: v == 0 ? negativeText : AppColors.deepNavy,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(height: 7, color: AppColors.sandBackground),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOutCubic,
                            builder: (context, f, _) => FractionallySizedBox(
                              widthFactor: f,
                              child: Container(height: 7, color: color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(product.categoriaNombre, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                        if (!product.activo) ...[
                          const SizedBox(width: 6),
                          const Text('· retirado del catálogo', style: TextStyle(fontSize: 10.5, color: AppColors.textLight)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ficha de un producto: indicadores del periodo y su propia tendencia.
Future<void> showProductDetail(BuildContext context, SalesChartsData data, ChartProduct p) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => _ProductDetail(data: data, product: p, controller: controller),
    ),
  );
}

class _ProductDetail extends StatefulWidget {
  final SalesChartsData data;
  final ChartProduct product;
  final ScrollController controller;
  const _ProductDetail({required this.data, required this.product, required this.controller});

  @override
  State<_ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<_ProductDetail> {
  bool _money = true;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final d = widget.data;
    final rank = 1 + d.products.where((o) => o.ingresos > p.ingresos).length;
    final serie = _money ? p.serieIngresos : p.serieUnidades;
    final maxV = serie.fold<double>(0, math.max);
    final color = categoryColor(p.categoria);
    final stats = <(String, String)>[
      ('Unidades vendidas', formatNumber(p.unidades)),
      ('Ingresos', formatMoney(p.ingresos)),
      ('Pedidos', formatNumber(p.pedidos.toDouble())),
      ('Ticket promedio', formatMoney(p.ticketPromedio)),
      ('Presente en', '${formatPct(p.frecuenciaPct)} de pedidos'),
      ('Precio actual', p.precio == null ? '—' : formatMoney(p.precio!)),
      ('Stock actual', p.stock == null ? '—' : formatNumber(p.stock!)),
      ('Rotación', p.rotacionPct == null ? '—' : formatPct(p.rotacionPct!)),
    ];

    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        Center(
          child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.sandBorder, borderRadius: BorderRadius.circular(2))),
        ),
        const SizedBox(height: 14),
        Text(p.nombre, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.deepNavy)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _Chip(text: p.categoriaNombre, color: color),
            _Chip(text: p.ingresos > 0 ? 'Puesto #$rank en ingresos' : 'Sin ventas en el periodo', color: AppColors.primaryDark),
            if (!p.activo) const _Chip(text: 'Retirado del catálogo', color: AppColors.textMuted),
          ],
        ),
        const SizedBox(height: 6),
        Text('${formatDate(d.desde)} – ${formatDate(d.hasta)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final w = (c.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final s in stats) SizedBox(width: w, child: AnalyticsStat(label: s.$1, value: s.$2))],
            );
          },
        ),
        const SizedBox(height: 18),
        const Text('Tendencia del producto', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.deepNavy)),
        const SizedBox(height: 8),
        AnalyticsSegmented(
          labels: const ['Ingresos', 'Unidades'],
          selected: _money ? 0 : 1,
          onChanged: (i) => setState(() => _money = i == 0),
        ),
        const SizedBox(height: 12),
        if (maxV <= 0)
          const ChartEmpty(message: 'Este producto no tuvo ventas en el periodo.')
        else
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxV * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxV * 1.2 / 4,
                  getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.sandBorder, strokeWidth: 1, dashArray: [4, 4]),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: maxV * 1.2 / 4,
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
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        final every = math.max(1, (serie.length / 4).ceil());
                        if (i < 0 || i >= serie.length || i % every != 0) return const SizedBox.shrink();
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text(bucketLabel(d.trend.labels[i], d.granularidad), style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.deepNavy,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                      '${bucketLabel(d.trend.labels[group.x], d.granularidad, long: true)}\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      children: [
                        TextSpan(
                          text: _money ? formatMoney(rod.toY) : '${formatNumber(rod.toY)} uds.',
                          style: const TextStyle(color: Color(0xFF7DD3FC), fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < serie.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: serie[i],
                        width: math.max(3, math.min(18, 220 / math.max(1, serie.length))),
                        color: color,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ]),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
