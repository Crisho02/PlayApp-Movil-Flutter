import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';

// Componentes y formatos comunes de la pestaña "Gráficos".

/// Formatos con coma decimal (es-CO), sin depender de inicialización de locales.
String formatPct(double v) => '${v.toStringAsFixed(1).replaceAll('.', ',')} %';

/// Cambio porcentual con signo (usa el signo menos tipográfico).
String formatChange(double v) {
  final abs = v.abs().toStringAsFixed(1).replaceAll('.', ',');
  if (v > 0.049) return '+$abs %';
  if (v < -0.049) return '−$abs %';
  return '0,0 %';
}

String hourLabel(int h) => '${h.toString().padLeft(2, '0')}:00';

/// Moneda completa: $1.250.000
String formatMoney(double v) => CurrencyFormatter.format(v.round());

/// Moneda abreviada para ejes y espacios reducidos, con el mismo estilo que [formatMoney]
/// (símbolo al final, como en el resto de la app): 1,2 M $ · 850 mil $ · 900 $
String formatMoneyCompact(double v) {
  final a = v.abs();
  final sign = v < 0 ? '−' : '';
  if (a >= 1e6) return '$sign${(a / 1e6).toStringAsFixed(a >= 1e7 ? 0 : 1).replaceAll('.', ',')} M \$';
  if (a >= 1e3) return '$sign${(a / 1e3).round()} mil \$';
  return '$sign${a.round()} \$';
}

/// Estilo de texto para lo que se dibuja a mano (CustomPainter), con la tipografía de la app.
TextStyle painterTextStyle(BuildContext context) => DefaultTextStyle.of(context).style.copyWith(
      decoration: TextDecoration.none,
      letterSpacing: 0,
      height: 1.0,
    );

/// Número sin decimales innecesarios: 12 · 12,5
String formatNumber(double v) {
  if ((v - v.roundToDouble()).abs() < 0.005) return _thousands(v.round());
  return v.toStringAsFixed(1).replaceAll('.', ',');
}

String _thousands(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '−' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

const List<String> _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
const List<String> weekdayShort = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const List<String> weekdayLong = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

/// "18 nov 2026"
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// Etiqueta de un periodo de la tendencia según la granularidad del backend.
/// day "2026-11-18" → "18 nov" · week → "sem 16 nov" · month "2026-11" → "nov 26"
String bucketLabel(String raw, String granularidad, {bool long = false}) {
  final parts = raw.split('-');
  if (parts.length < 2) return raw;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) return raw;
  final m = _months[month - 1];
  if (granularidad == 'month' || parts.length == 2) {
    return long ? '$m $year' : '$m ${(year % 100).toString().padLeft(2, '0')}';
  }
  final day = int.tryParse(parts[2]) ?? 1;
  if (granularidad == 'week') return long ? 'Semana del $day $m $year' : 'sem $day $m';
  return long ? '$day $m $year' : '$day $m';
}

/// Colores fijos por categoría (1 Comida, 2 Bebida, 3 Servicio).
Color categoryColor(int? id) => switch (id) {
      1 => AppColors.coral,
      2 => AppColors.primary,
      3 => AppColors.turquoise,
      _ => AppColors.textLight,
    };

/// Paleta para comparar productos (distinguibles entre sí y en daltonismo leve).
const List<Color> seriesPalette = [AppColors.primary, AppColors.coral, Color(0xFF0F766E)];

const Color positiveText = Color(0xFF0F766E);
const Color negativeText = Color(0xFFC2410C);

/// Escala secuencial: cielo claro → celeste → turquesa → amarillo → coral.
/// Cada paso es de un tono vecino, así la mezcla nunca produce grises ni morados apagados.
const List<Color> _heatStops = [
  Color(0xFFE0F2FE),
  Color(0xFF7DD3FC),
  AppColors.turquoise,
  Color(0xFFFACC15),
  AppColors.coral,
];

/// Color para un valor dentro de 0..[max].
Color heatColor(double value, {double max = 100}) {
  final t = (value / (max <= 0 ? 1 : max)).clamp(0.0, 1.0);
  final scaled = t * (_heatStops.length - 1);
  final i = scaled.floor().clamp(0, _heatStops.length - 2);
  return Color.lerp(_heatStops[i], _heatStops[i + 1], scaled - i)!;
}

LinearGradient heatGradient() => const LinearGradient(colors: _heatStops);

Color readableOn(Color bg) => bg.computeLuminance() > 0.45 ? AppColors.deepNavy : Colors.white;

/// Contenedor estándar de cada gráfica, con el mismo estilo que el resto del panel admin.
class AnalyticsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const AnalyticsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.deepNavy),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Selector segmentado propio: nunca desborda (cada opción se reduce con FittedBox).
class AnalyticsSegmented extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const AnalyticsSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.sandBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selected,
                label: labels[i],
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    constraints: const BoxConstraints(minHeight: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: i == selected
                          ? [
                              BoxShadow(
                                color: AppColors.deepNavy.withValues(alpha: 0.10),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labels[i],
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: i == selected ? FontWeight.bold : FontWeight.w500,
                          color: i == selected ? AppColors.primaryDark : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dato destacado (valor grande + etiqueta) usado debajo de las gráficas.
class AnalyticsStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;

  const AnalyticsStat({super.key, required this.label, required this.value, this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.sandBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: accent ?? AppColors.deepNavy),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado vacío de una gráfica (periodo sin ventas).
class ChartEmpty extends StatelessWidget {
  final String message;
  const ChartEmpty({super.key, this.message = 'No hay ventas en el periodo seleccionado.'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.sandBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.insert_chart_outlined_rounded, size: 30, color: AppColors.textLight),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.3),
          ),
        ],
      ),
    );
  }
}

/// Insignia de cambio frente al periodo anterior: ↑ verde, ↓ coral, "—" si no hay comparación.
class ChangeBadge extends StatelessWidget {
  final double? cambioPct;
  const ChangeBadge({super.key, required this.cambioPct});

  @override
  Widget build(BuildContext context) {
    final v = cambioPct;
    final up = v != null && v > 0.049;
    final down = v != null && v < -0.049;
    final color = up ? positiveText : down ? negativeText : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (up || down) Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 12, color: color),
          if (up || down) const SizedBox(width: 2),
          Text(
            v == null ? '—' : formatChange(v),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
