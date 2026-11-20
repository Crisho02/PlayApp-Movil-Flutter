import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/sales_charts_model.dart';
import 'charts_common.dart';

/// Gráfica 7: participación de cada categoría. Permite filtrar toda la pestaña por una categoría.
class CategoryMixCard extends StatefulWidget {
  final SalesChartsData data;

  /// Aplica (id) o quita (null) el filtro de categoría en todas las gráficas.
  final ValueChanged<int?> onFilter;

  const CategoryMixCard({super.key, required this.data, required this.onFilter});

  @override
  State<CategoryMixCard> createState() => _CategoryMixCardState();
}

class _CategoryMixCardState extends State<CategoryMixCard> {
  bool _units = false;
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final items = d.categoryMix.where((c) => (_units ? c.unidades : c.ingresos) > 0).toList();
    final total = items.fold<double>(0, (a, c) => a + (_units ? c.unidades : c.ingresos));
    final touched = (_touched != null && _touched! < items.length) ? _touched : null;
    final focus = touched == null ? null : items[touched];

    return AnalyticsCard(
      icon: Icons.donut_large_rounded,
      title: 'Mix por categoría',
      subtitle: 'Peso de cada categoría en el periodo. Usa "Filtrar" para aplicar una categoría a todas las gráficas.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnalyticsSegmented(
            labels: const ['Ingresos', 'Unidades'],
            selected: _units ? 1 : 0,
            onChanged: (i) => setState(() {
              _units = i == 1;
              _touched = null;
            }),
          ),
          const SizedBox(height: 14),
          if (total <= 0)
            const ChartEmpty()
          else ...[
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 62,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (event is FlTapUpEvent) {
                            final i = response?.touchedSection?.touchedSectionIndex;
                            setState(() => _touched = (i == null || i < 0 || i == _touched) ? null : i);
                          }
                        },
                      ),
                      sections: [
                        for (var i = 0; i < items.length; i++)
                          PieChartSectionData(
                            value: _units ? items[i].unidades : items[i].ingresos,
                            color: categoryColor(items[i].id),
                            radius: i == touched ? 46 : 38,
                            showTitle: (_units ? items[i].unidades : items[i].ingresos) / total >= 0.07,
                            title: formatPct((_units ? items[i].unidades : items[i].ingresos) * 100 / total).replaceAll(',0 %', ' %'),
                            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 300),
                  ),
                  IgnorePointer(
                    child: SizedBox(
                      width: 110,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            focus?.nombre ?? 'Total',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _value(focus == null ? total : (_units ? focus.unidades : focus.ingresos), compact: true),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
                            ),
                          ),
                          if (focus != null)
                            Text(
                              '${formatNumber(focus.pedidos.toDouble())} pedidos',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final c in d.categoryMix)
              _CategoryRow(
                share: c,
                value: _units ? c.unidades : c.ingresos,
                total: total,
                formatted: _value(_units ? c.unidades : c.ingresos),
                active: d.categoria == c.id,
                canFilter: c.id >= 1 && c.id <= 3,
                onFilter: () => widget.onFilter(d.categoria == c.id ? null : c.id),
              ),
            if (d.categoria != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => widget.onFilter(null),
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                  label: const Text('Quitar filtro de categoría'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark, minimumSize: const Size(48, 40)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _value(double v, {bool compact = false}) =>
      _units ? '${formatNumber(v)} uds.' : (compact ? formatMoneyCompact(v) : formatMoney(v));
}

class _CategoryRow extends StatelessWidget {
  final CategoryShare share;
  final double value;
  final double total;
  final String formatted;
  final bool active;
  final bool canFilter;
  final VoidCallback onFilter;

  const _CategoryRow({
    required this.share,
    required this.value,
    required this.total,
    required this.formatted,
    required this.active,
    required this.canFilter,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(share.id);
    final pct = total <= 0 ? 0.0 : value * 100 / total;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? color : Colors.transparent),
      ),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(share.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
                Text(
                  '$formatted · ${formatPct(pct)}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canFilter)
            TextButton.icon(
              onPressed: onFilter,
              icon: Icon(active ? Icons.check_circle_rounded : Icons.filter_alt_rounded, size: 16),
              label: Text(active ? 'Filtrado' : 'Filtrar', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: active ? color : AppColors.primaryDark,
                minimumSize: const Size(48, 40),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
        ],
      ),
    );
  }
}
