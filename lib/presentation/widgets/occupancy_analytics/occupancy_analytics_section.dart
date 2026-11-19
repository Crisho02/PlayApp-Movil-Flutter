import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/occupancy_analytics_model.dart';
import '../../../providers/admin_provider.dart';
import 'hourly_curve_card.dart';
import 'sensitivity_card.dart';
import 'weekly_heatmap_card.dart';

/// Sección "Análisis de la red neuronal": 3 gráficas interactivas calculadas con el modelo real.
/// Se muestra dentro de la pestaña Clima & Afluencia, debajo de "Ocupación Estimada en Playa".
class OccupancyAnalyticsSection extends StatefulWidget {
  const OccupancyAnalyticsSection({super.key});

  @override
  State<OccupancyAnalyticsSection> createState() => _OccupancyAnalyticsSectionState();
}

class _OccupancyAnalyticsSectionState extends State<OccupancyAnalyticsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProvider>().fetchOccupancyAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final data = admin.occupancyAnalytics;
        if (data != null) return _AnalyticsContent(data: data);
        if (admin.analyticsError != null && !admin.isAnalyticsLoading) {
          return _AnalyticsError(
            message: admin.analyticsError!,
            onRetry: () => admin.fetchOccupancyAnalytics(force: true),
          );
        }
        return const _AnalyticsLoading();
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String? version;
  const _SectionHeader({this.version});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Análisis de la red neuronal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Datos simulados',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          version == null || version!.isEmpty
              ? 'Escenarios evaluados con el modelo de ocupación de Bocagrande.'
              : 'Escenarios evaluados con el modelo de ocupación de Bocagrande · versión $version',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
        ),
      ],
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  final OccupancyAnalytics data;
  const _AnalyticsContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(version: data.modelVersion),
        const SizedBox(height: 12),
        HourlyCurveCard(data: data.hourly),
        const SizedBox(height: 16),
        WeeklyHeatmapCard(data: data.heatmap),
        const SizedBox(height: 16),
        SensitivityCard(bases: data.sensitivity),
        const SizedBox(height: 16),
        _ModelReliability(evaluation: data.evaluation, notice: data.notice),
      ],
    );
  }
}

/// Transparencia: error del modelo frente a la referencia y aviso de que los datos son simulados.
class _ModelReliability extends StatelessWidget {
  final ModelEvaluation? evaluation;
  final String notice;
  const _ModelReliability({required this.evaluation, required this.notice});

  @override
  Widget build(BuildContext context) {
    final e = evaluation;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF92400E)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cómo leer estas gráficas',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (e != null && e.baselineMae > 0) ...[
            _ErrorBar(label: 'Error medio de la red neuronal', value: e.mae, max: e.baselineMae, color: AppColors.turquoise),
            const SizedBox(height: 8),
            _ErrorBar(label: 'Error si se predijera siempre el promedio', value: e.baselineMae, max: e.baselineMae, color: AppColors.textLight),
            const SizedBox(height: 10),
          ],
          Text(
            notice.isEmpty
                ? 'Entrenada solo con datos simulados: describe el comportamiento del modelo, no mediciones reales de la playa.'
                : notice,
            style: const TextStyle(fontSize: 12, color: AppColors.textMain, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  const _ErrorBar({required this.label, required this.value, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.toStringAsFixed(2).replaceAll('.', ',')} pp',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (value / max).clamp(0.02, 1.0),
            minHeight: 8,
            backgroundColor: Colors.white,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _AnalyticsLoading extends StatelessWidget {
  const _AnalyticsLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: const Column(
            children: [
              SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary)),
              SizedBox(height: 14),
              Text(
                'Calculando escenarios con la red neuronal…',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalyticsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _AnalyticsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            children: [
              const Icon(Icons.cloud_off_rounded, size: 32, color: AppColors.textLight),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.35),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(48, 44),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
