import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/occupancy_analytics_model.dart';
import 'analytics_common.dart';

/// Gráfica 3: impacto de cada variable sobre la ocupación (barras tipo tornado o radar).
/// Es descriptiva: muestra cómo responde el modelo al cambiar UNA variable, no una relación causal.
class SensitivityCard extends StatefulWidget {
  final List<SensitivityBase> bases;
  const SensitivityCard({super.key, required this.bases});

  @override
  State<SensitivityCard> createState() => _SensitivityCardState();
}

class _SensitivityCardState extends State<SensitivityCard> {
  int _baseIndex = 0;
  bool _radar = false;
  String? _selectedId;

  SensitivityBase get _base => widget.bases[_baseIndex.clamp(0, widget.bases.length - 1)];

  List<SensitivityFactor> get _sorted {
    final list = [..._base.factors];
    list.sort((a, b) => b.impact.compareTo(a.impact));
    return list;
  }

  SensitivityFactor get _selected {
    final factors = _base.factors;
    return factors.firstWhere((f) => f.id == _selectedId, orElse: () => _sorted.first);
  }

  @override
  Widget build(BuildContext context) {
    final base = _base;
    final selected = _selected;

    return AnalyticsCard(
      icon: Icons.tune_rounded,
      title: 'Qué mueve la ocupación',
      subtitle: 'Cuánto cambia la predicción al modificar una sola variable. El resto del escenario se mantiene igual.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnalyticsSegmented(
            labels: [for (final b in widget.bases) b.label],
            selected: _baseIndex,
            onChanged: (i) => setState(() => _baseIndex = i),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 190,
              child: AnalyticsSegmented(
                labels: const ['Barras', 'Radar'],
                selected: _radar ? 1 : 0,
                onChanged: (i) => setState(() => _radar = i == 1),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _BaselineBanner(baseline: base.baseline, label: base.label),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            child: _radar
                ? _RadarView(
                    key: ValueKey('radar-${base.id}'),
                    factors: base.factors,
                    selectedId: selected.id,
                    onSelect: (id) => setState(() => _selectedId = id),
                  )
                : _TornadoView(
                    key: ValueKey('bars-${base.id}'),
                    factors: _sorted,
                    selectedId: selected.id,
                    onSelect: (id) => setState(() => _selectedId = id),
                  ),
          ),
          const SizedBox(height: 14),
          _FactorDetail(factor: selected, baseline: base.baseline),
        ],
      ),
    );
  }
}

class _BaselineBanner extends StatelessWidget {
  final double baseline;
  final String label;
  const _BaselineBanner({required this.baseline, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sandBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 36,
            decoration: BoxDecoration(color: occupancyColor(baseline), borderRadius: BorderRadius.circular(5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ocupación del escenario base', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.deepNavy),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Ancho máximo: sin él el FittedBox toma su ancho natural y deja sin espacio al texto.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatPct(baseline),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barras divergentes: izquierda = baja la ocupación (coral), derecha = la sube (turquesa).
class _TornadoView extends StatelessWidget {
  final List<SensitivityFactor> factors;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _TornadoView({super.key, required this.factors, required this.selectedId, required this.onSelect});

  double _minDelta(SensitivityFactor f) => math.min(0, f.options.map((o) => o.delta).reduce(math.min));
  double _maxDelta(SensitivityFactor f) => math.max(0, f.options.map((o) => o.delta).reduce(math.max));

  @override
  Widget build(BuildContext context) {
    final leftSpan = factors.map((f) => -_minDelta(f)).fold(0.0, math.max);
    final rightSpan = factors.map(_maxDelta).fold(0.0, math.max);
    final total = math.max(leftSpan + rightSpan, 1.0);
    final leftFrac = (leftSpan / total).clamp(0.15, 0.85);

    return Column(
      children: [
        for (final f in factors)
          _TornadoRow(
            factor: f,
            selected: f.id == selectedId,
            minDelta: _minDelta(f),
            maxDelta: _maxDelta(f),
            leftSpan: math.max(leftSpan, 1.0),
            rightSpan: math.max(rightSpan, 1.0),
            leftFrac: leftFrac,
            onTap: () => onSelect(f.id),
          ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 14, color: AppColors.coral),
                  SizedBox(width: 3),
                  Flexible(child: Text('Reduce la ocupación', style: TextStyle(fontSize: 11, color: AppColors.coral, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            SizedBox(width: 8),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text('La aumenta', style: TextStyle(fontSize: 11, color: Color(0xFF0F766E), fontWeight: FontWeight.w600))),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0F766E)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TornadoRow extends StatelessWidget {
  final SensitivityFactor factor;
  final bool selected;
  final double minDelta;
  final double maxDelta;
  final double leftSpan;
  final double rightSpan;
  final double leftFrac;
  final VoidCallback onTap;

  const _TornadoRow({
    required this.factor,
    required this.selected,
    required this.minDelta,
    required this.maxDelta,
    required this.leftSpan,
    required this.rightSpan,
    required this.leftFrac,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${factor.label}: de ${formatDelta(minDelta)} a ${formatDelta(maxDelta)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.07) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      factor.label,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepNavy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (minDelta < -0.049)
                            Text(
                              formatDelta(minDelta),
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.coral),
                            ),
                          if (minDelta < -0.049 && maxDelta > 0.049)
                            const Text('  ·  ', style: TextStyle(fontSize: 11.5, color: AppColors.textLight)),
                          if (maxDelta > 0.049)
                            Text(
                              formatDelta(maxDelta),
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                            ),
                          if (minDelta >= -0.049 && maxDelta <= 0.049)
                            const Text('sin efecto', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 14,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final axisX = w * leftFrac;
                    final negW = (-minDelta / leftSpan) * axisX;
                    final posW = (maxDelta / rightSpan) * (w - axisX);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.sandBackground,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          left: axisX - negW,
                          top: 0,
                          bottom: 0,
                          width: negW,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              color: AppColors.coral,
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(7)),
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          left: axisX,
                          top: 0,
                          bottom: 0,
                          width: posW,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              color: AppColors.turquoise,
                              borderRadius: BorderRadius.horizontal(right: Radius.circular(7)),
                            ),
                          ),
                        ),
                        Positioned(
                          left: axisX - 0.75,
                          top: -2,
                          bottom: -2,
                          width: 1.5,
                          child: const ColoredBox(color: AppColors.deepNavy),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Radar: dos polígonos, la mayor caída y el mayor aumento de ocupación por variable.
class _RadarView extends StatelessWidget {
  final List<SensitivityFactor> factors;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _RadarView({super.key, required this.factors, required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final drops = [for (final f in factors) -math.min(0.0, f.options.map((o) => o.delta).reduce(math.min))];
    final gains = [for (final f in factors) math.max(0.0, f.options.map((o) => o.delta).reduce(math.max))];

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              tickCount: 4,
              ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 1),
              tickBorderData: const BorderSide(color: AppColors.sandBorder, width: 1),
              gridBorderData: const BorderSide(color: AppColors.sandBorder, width: 1),
              radarBorderData: const BorderSide(color: AppColors.sandBorder, width: 1.5),
              titlePositionPercentageOffset: 0.16,
              titleTextStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.deepNavy),
              getTitle: (index, angle) => RadarChartTitle(
                text: factors[index].label,
                angle: 0,
              ),
              dataSets: [
                RadarDataSet(
                  fillColor: AppColors.coral.withValues(alpha: 0.22),
                  borderColor: AppColors.coral,
                  borderWidth: 2,
                  entryRadius: 3.5,
                  dataEntries: [for (final v in drops) RadarEntry(value: v)],
                ),
                RadarDataSet(
                  fillColor: AppColors.turquoise.withValues(alpha: 0.22),
                  borderColor: AppColors.turquoise,
                  borderWidth: 2,
                  entryRadius: 3.5,
                  dataEntries: [for (final v in gains) RadarEntry(value: v)],
                ),
              ],
              radarTouchData: RadarTouchData(
                touchSpotThreshold: 28,
                touchCallback: (event, response) {
                  final spot = response?.touchedSpot;
                  if (event is FlTapUpEvent && spot != null) {
                    final i = spot.touchedRadarEntryIndex;
                    if (i >= 0 && i < factors.length) onSelect(factors[i].id);
                  }
                },
              ),
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 6,
          children: [
            const _RadarLegend(color: AppColors.coral, label: 'Mayor caída'),
            const _RadarLegend(color: AppColors.turquoise, label: 'Mayor aumento'),
            const Text(
              'Toca un punto para ver el detalle',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}

class _RadarLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _RadarLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Detalle de la variable seleccionada: valor resultante y diferencia por cada opción probada.
class _FactorDetail extends StatelessWidget {
  final SensitivityFactor factor;
  final double baseline;
  const _FactorDetail({required this.factor, required this.baseline});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(factor.id),
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
              factor.label,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
            ),
            const SizedBox(height: 8),
            for (final o in factor.options)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                // Wrap: si no cabe todo en una línea (texto ampliado, pantallas angostas) el resultado baja
                // a la línea siguiente; FittedBox evita cualquier desborde residual.
                child: LayoutBuilder(
                  builder: (context, c) => Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: c.maxWidth),
                        child: Text(
                          o.label,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textMain),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: c.maxWidth),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatPct(o.value),
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.deepNavy),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                constraints: const BoxConstraints(minWidth: 74),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (o.delta < -0.049 ? AppColors.coral : o.delta > 0.049 ? AppColors.turquoise : AppColors.textLight)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  formatDelta(o.delta),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: o.delta < -0.049
                                        ? const Color(0xFFC2410C)
                                        : o.delta > 0.049
                                            ? const Color(0xFF0F766E)
                                            : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
