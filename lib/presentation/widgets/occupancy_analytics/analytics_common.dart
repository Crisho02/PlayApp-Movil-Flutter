import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Formatos con coma decimal (es-CO), sin depender de inicialización de locales.
String formatPct(double v) => '${v.toStringAsFixed(1).replaceAll('.', ',')} %';

/// Diferencia en puntos porcentuales con signo (usa el signo menos tipográfico).
String formatDelta(double v) {
  final abs = v.abs().toStringAsFixed(1).replaceAll('.', ',');
  if (v > 0.049) return '+$abs pp';
  if (v < -0.049) return '−$abs pp';
  return '0,0 pp';
}

String hourLabel(int h) => '${h.toString().padLeft(2, '0')}:00';

/// Escala secuencial de ocupación: cielo claro → celeste → turquesa → amarillo → coral.
/// Cada paso es de un tono vecino, así la mezcla nunca produce grises ni morados apagados.
const List<Color> _occupancyStops = [
  Color(0xFFE0F2FE),
  Color(0xFF7DD3FC),
  AppColors.turquoise,
  Color(0xFFFACC15),
  AppColors.coral,
];

/// Color para un porcentaje. [max] es el valor que recibe el extremo más cálido de la escala.
Color occupancyColor(double pct, {double max = 100}) {
  final t = (pct / (max <= 0 ? 100 : max)).clamp(0.0, 1.0);
  final scaled = t * (_occupancyStops.length - 1);
  final i = scaled.floor().clamp(0, _occupancyStops.length - 2);
  return Color.lerp(_occupancyStops[i], _occupancyStops[i + 1], scaled - i)!;
}

LinearGradient occupancyGradient() => const LinearGradient(colors: _occupancyStops);

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
