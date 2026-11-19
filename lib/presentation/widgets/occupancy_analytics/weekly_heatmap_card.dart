import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/occupancy_analytics_model.dart';
import 'analytics_common.dart';

/// Gráfica 2: mapa de calor día de la semana × hora, con selector de temporada.
/// Se puede tocar o arrastrar el dedo sobre la cuadrícula para inspeccionar cada celda.
class WeeklyHeatmapCard extends StatefulWidget {
  final HeatmapAnalytics data;
  const WeeklyHeatmapCard({super.key, required this.data});

  @override
  State<WeeklyHeatmapCard> createState() => _WeeklyHeatmapCardState();
}

class _WeeklyHeatmapCardState extends State<WeeklyHeatmapCard> {
  static const _dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  int _season = 0;
  bool _fullDay = false; // false: 06–18 h, true: 24 h
  int? _row;
  int? _col;

  int get _firstHour => _fullDay ? 0 : 6;
  int get _lastHour => _fullDay ? 23 : 17; // 06:00–17:59, las horas de sol del modelo

  List<List<double>> get _grid => widget.data.grid(widget.data.seasons[_season].id);

  /// Celda con mayor ocupación dentro del rango de horas visible.
  (int, int) _best() {
    var bestRow = 0, bestCol = _firstHour;
    var best = -1.0;
    final grid = _grid;
    for (var r = 0; r < grid.length; r++) {
      for (var c = _firstHour; c <= _lastHour; c++) {
        if (grid[r][c] > best) {
          best = grid[r][c];
          bestRow = r;
          bestCol = c;
        }
      }
    }
    return (bestRow, bestCol);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final grid = _grid;
    final (bestRow, bestCol) = _best();
    var row = _row ?? bestRow;
    var col = _col ?? bestCol;
    if (col < _firstHour || col > _lastHour) col = bestCol;
    row = row.clamp(0, grid.length - 1);
    final value = grid[row][col];
    final dayAvg = grid[row].sublist(6, 18).reduce((a, b) => a + b) / 12;
    final isBest = row == bestRow && col == bestCol;
    final scaleMax = data.maxValue;
    final valueColor = occupancyColor(value, max: scaleMax);

    return AnalyticsCard(
      icon: Icons.grid_view_rounded,
      title: 'Mapa de calor semanal',
      subtitle: 'Ocupación esperada por día y hora. Toca una celda o desliza sobre una fila para ver el detalle.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnalyticsSegmented(
            labels: [for (final s in data.seasons) s.label],
            selected: _season,
            onChanged: (i) => setState(() => _season = i),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 190,
              child: AnalyticsSegmented(
                labels: const ['06–18 h', '24 h'],
                selected: _fullDay ? 1 : 0,
                onChanged: (i) => setState(() => _fullDay = i == 1),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _HeatGrid(
            grid: grid,
            scaleMax: scaleMax,
            days: data.days,
            firstHour: _firstHour,
            lastHour: _lastHour,
            selectedRow: row,
            selectedCol: col,
            onSelect: (r, c) => setState(() {
              _row = r;
              _col = c;
            }),
          ),
          const SizedBox(height: 12),
          _Legend(maxLabel: '${scaleMax.round()} %'),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sandBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: valueColor.withValues(alpha: 0.7), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: valueColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '${value.round()}%',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: readableOn(valueColor)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_dayNames[row]} · ${hourLabel(col)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.deepNavy),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatPct(value)} estimada'
                        '${isBest ? ' · mejor momento de la semana' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMain),
                      ),
                      Text(
                        'Promedio de ese día (06–18 h): ${formatPct(dayAvg)}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isBest) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _row = null;
                  _col = null;
                }),
                icon: const Icon(Icons.bolt_rounded, size: 16),
                label: Text('Ir al pico: ${_dayNames[bestRow]} ${hourLabel(bestCol)}'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(48, 40),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String maxLabel;
  const _Legend({required this.maxLabel});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 11, color: AppColors.textMuted);
    return Row(
      children: [
        const Text('0 %', style: style),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              gradient: occupancyGradient(),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(maxLabel, style: style),
      ],
    );
  }
}

/// Cuadrícula dibujada con CustomPainter: ligera (hasta 168 celdas) y con selección táctil exacta.
class _HeatGrid extends StatelessWidget {
  final List<List<double>> grid;
  final double scaleMax;
  final List<String> days;
  final int firstHour;
  final int lastHour;
  final int selectedRow;
  final int selectedCol;
  final void Function(int row, int col) onSelect;

  const _HeatGrid({
    required this.grid,
    required this.scaleMax,
    required this.days,
    required this.firstHour,
    required this.lastHour,
    required this.selectedRow,
    required this.selectedCol,
    required this.onSelect,
  });

  static const double _labelWidth = 34;
  static const double _headerHeight = 20;
  static const double _rowHeight = 30;

  @override
  Widget build(BuildContext context) {
    final rows = grid.length;
    final cols = lastHour - firstHour + 1;
    final height = _headerHeight + rows * _rowHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - _labelWidth) / cols;

        // Toque: elige fila y columna. Arrastre horizontal: recorre las horas de la fila actual.
        // El arrastre vertical queda libre para que la pantalla siga haciendo scroll.
        void pick(Offset p, {bool keepRow = false}) {
          final c = ((p.dx - _labelWidth) / cellWidth).floor();
          final r = keepRow ? selectedRow : ((p.dy - _headerHeight) / _rowHeight).floor();
          if (c < 0 || c >= cols || r < 0 || r >= rows) return;
          if (r != selectedRow || c + firstHour != selectedCol) onSelect(r, c + firstHour);
        }

        return Semantics(
          label: 'Mapa de calor de ocupación por día y hora',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => pick(d.localPosition),
            onHorizontalDragStart: (d) => pick(d.localPosition),
            onHorizontalDragUpdate: (d) => pick(d.localPosition, keepRow: true),
            child: TweenAnimationBuilder<double>(
              key: ValueKey('$firstHour-$lastHour-${grid.hashCode}'),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => CustomPaint(
                size: Size(constraints.maxWidth, height),
                painter: _HeatPainter(
                  grid: grid,
                  scaleMax: scaleMax,
                  days: days,
                  firstHour: firstHour,
                  lastHour: lastHour,
                  selectedRow: selectedRow,
                  selectedCol: selectedCol,
                  progress: t,
                ),
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
  final double scaleMax;
  final List<String> days;
  final int firstHour;
  final int lastHour;
  final int selectedRow;
  final int selectedCol;
  final double progress;

  _HeatPainter({
    required this.grid,
    required this.scaleMax,
    required this.days,
    required this.firstHour,
    required this.lastHour,
    required this.selectedRow,
    required this.selectedCol,
    required this.progress,
  });

  void _text(Canvas canvas, String text, Offset center, {bool bold = false, Color color = AppColors.textMuted, double size = 10}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, color: color, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const labelW = _HeatGrid._labelWidth;
    const headerH = _HeatGrid._headerHeight;
    const rowH = _HeatGrid._rowHeight;
    final cols = lastHour - firstHour + 1;
    final cellW = (size.width - labelW) / cols;
    const gap = 1.5;

    // Etiquetas de hora (cada 2 h en vista 06–18; cada 3 h en 24 h).
    final step = cols > 14 ? 3 : 2;
    for (var c = 0; c < cols; c++) {
      final h = firstHour + c;
      if (h % step != 0) continue;
      final selected = h == selectedCol;
      _text(canvas, '$h', Offset(labelW + c * cellW + cellW / 2, headerH / 2),
          bold: selected, color: selected ? AppColors.primaryDark : AppColors.textMuted);
    }

    for (var r = 0; r < grid.length; r++) {
      final selectedDay = r == selectedRow;
      _text(canvas, r < days.length ? days[r] : '', Offset(labelW / 2 - 2, headerH + r * rowH + rowH / 2),
          bold: selectedDay, color: selectedDay ? AppColors.primaryDark : AppColors.textMuted, size: 11);
      for (var c = 0; c < cols; c++) {
        final v = grid[r][firstHour + c];
        final rect = Rect.fromLTWH(labelW + c * cellW + gap / 2, headerH + r * rowH + gap / 2, cellW - gap, rowH - gap);
        final fade = occupancyColor(v * progress, max: scaleMax);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), Paint()..color = fade);
      }
    }

    // Selección: contorno de la celda + guías suaves de fila y columna.
    if (selectedCol >= firstHour && selectedCol <= lastHour && selectedRow < grid.length) {
      final c = selectedCol - firstHour;
      final guide = Paint()
        ..color = AppColors.deepNavy.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final rowRect = Rect.fromLTWH(labelW, headerH + selectedRow * rowH, size.width - labelW, rowH);
      canvas.drawRRect(RRect.fromRectAndRadius(rowRect, const Radius.circular(4)), guide);
      final cell = Rect.fromLTWH(labelW + c * cellW, headerH + selectedRow * rowH, cellW, rowH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(cell.deflate(0.5), const Radius.circular(4)),
        Paint()
          ..color = AppColors.deepNavy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) =>
      old.progress != progress ||
      old.scaleMax != scaleMax ||
      old.selectedRow != selectedRow ||
      old.selectedCol != selectedCol ||
      old.firstHour != firstHour ||
      old.lastHour != lastHour ||
      !identical(old.grid, grid);
}
