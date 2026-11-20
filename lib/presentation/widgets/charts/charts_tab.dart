import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/sales_charts_model.dart';
import '../../../providers/admin_provider.dart';
import 'category_mix_card.dart';
import 'charts_common.dart';
import 'kpi_section.dart';
import 'orders_heatmap_card.dart';
import 'pareto_card.dart';
import 'product_comparator_card.dart';
import 'product_ranking_card.dart';
import 'sales_trend_card.dart';

/// Pestaña "Gráficos" del panel admin: 7 gráficas con datos en vivo de la base de datos.
class ChartsTab extends StatefulWidget {
  const ChartsTab({super.key});

  @override
  State<ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends State<ChartsTab> {
  TrendMetric _metric = TrendMetric.ingresos;

  static const _ranges = [
    ('7d', '7 días'),
    ('30d', '30 días'),
    ('90d', '90 días'),
    ('365d', '1 año'),
    ('todo', 'Todo'),
    ('personalizado', 'Personalizado'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final admin = context.read<AdminProvider>();
      if (admin.salesCharts == null && !admin.isChartsLoading) admin.fetchSalesCharts();
    });
  }

  Future<void> _apply(ChartsFilter f) => context.read<AdminProvider>().fetchSalesCharts(filter: f);

  /// Filtro vigente en el momento del toque (no el capturado en el último build),
  /// para que dos cambios seguidos no se pisen.
  ChartsFilter get _current => context.read<AdminProvider>().chartsFilter;

  Future<void> _setRange(AdminProvider admin, String r) =>
      r == 'personalizado' ? _pickRange(admin) : _apply(_current.copyWith(rango: r));

  Future<void> _setCategory(int? c) =>
      _apply(c == null ? _current.copyWith(clearCategoria: true) : _current.copyWith(categoria: c));

  Future<void> _pickRange(AdminProvider admin) async {
    final now = DateTime.now();
    final f = _current;
    final data = admin.salesCharts;
    final initial = DateTimeRange(
      start: f.desde ?? data?.desde ?? now.subtract(const Duration(days: 29)),
      end: f.hasta ?? data?.hasta ?? now,
    );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: initial.end.isAfter(now) ? DateTimeRange(start: initial.start, end: now) : initial,
      helpText: 'Selecciona el periodo',
      saveText: 'Aplicar',
    );
    if (picked != null && mounted) {
      await _apply(_current.copyWith(rango: 'personalizado', desde: picked.start, hasta: picked.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final data = admin.salesCharts;
        final f = admin.chartsFilter;
        return RefreshIndicator(
          onRefresh: () => admin.fetchSalesCharts(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _Header(data: data),
              const SizedBox(height: 12),
              _FilterBar(
                filter: f,
                ranges: _ranges,
                onRange: (r) => _setRange(admin, r),
                onCategory: _setCategory,
              ),
              if (data != null) ...[
                const SizedBox(height: 8),
                _PeriodLine(data: data),
              ],
              SizedBox(
                height: 4,
                child: admin.isChartsLoading && data != null
                    ? const LinearProgressIndicator(minHeight: 3, color: AppColors.primary, backgroundColor: Colors.transparent)
                    : null,
              ),
              if (admin.chartsError != null && data != null) ...[
                const SizedBox(height: 8),
                _InlineError(message: admin.chartsError!, onRetry: () => admin.fetchSalesCharts()),
              ],
              const SizedBox(height: 10),
              if (data == null && admin.chartsError != null && !admin.isChartsLoading)
                _FullError(message: admin.chartsError!, onRetry: () => admin.fetchSalesCharts())
              else if (data == null)
                const _Loading()
              else ...[
                KpiSection(data: data, selected: _metric, onSelect: (m) => setState(() => _metric = m)),
                const SizedBox(height: 16),
                SalesTrendCard(
                  data: data,
                  metric: _metric,
                  onMetric: (m) => setState(() => _metric = m),
                  granularity: f.granularidad,
                  onGranularity: (g) => _apply(_current.copyWith(granularidad: g)),
                ),
                const SizedBox(height: 16),
                ProductRankingCard(data: data),
                const SizedBox(height: 16),
                ProductComparatorCard(data: data),
                const SizedBox(height: 16),
                ParetoCard(data: data),
                const SizedBox(height: 16),
                OrdersHeatmapCard(data: data),
                const SizedBox(height: 16),
                CategoryMixCard(data: data, onFilter: _setCategory),
                const SizedBox(height: 16),
                const _Footnote(),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final SalesChartsData? data;
  const _Header({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = data?.generatedAt;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gráficos de ventas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.deepNavy)),
              const SizedBox(height: 2),
              Text(
                t == null
                    ? 'Información en vivo desde la base de datos.'
                    : 'En vivo desde la base de datos · actualizado ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: AppColors.success),
              SizedBox(width: 5),
              Text('En vivo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final ChartsFilter filter;
  final List<(String, String)> ranges;
  final ValueChanged<String> onRange;
  final ValueChanged<int?> onCategory;

  const _FilterBar({required this.filter, required this.ranges, required this.onRange, required this.onCategory});

  @override
  Widget build(BuildContext context) {
    final catIndex = filter.categoria == null ? 0 : filter.categoria!.clamp(1, 3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ranges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final (id, label) = ranges[i];
              final selected = filter.rango == id;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (id == 'personalizado') ...[
                      Icon(Icons.date_range_rounded, size: 15, color: selected ? Colors.white : AppColors.primaryDark),
                      const SizedBox(width: 4),
                    ],
                    Text(label),
                  ],
                ),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) => onRange(id),
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                side: BorderSide(color: selected ? AppColors.primary : AppColors.sandBorder),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textMain,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        AnalyticsSegmented(
          labels: const ['Todas', 'Comida', 'Bebida', 'Servicio'],
          selected: catIndex,
          onChanged: (i) => onCategory(i == 0 ? null : i),
        ),
      ],
    );
  }
}

class _PeriodLine extends StatelessWidget {
  final SalesChartsData data;
  const _PeriodLine({required this.data});

  @override
  Widget build(BuildContext context) {
    final cat = data.categoria == null ? null : data.categories[data.categoria];
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.35),
        children: [
          const WidgetSpan(child: Icon(Icons.event_rounded, size: 13, color: AppColors.textMuted), alignment: PlaceholderAlignment.middle),
          TextSpan(text: ' ${formatDate(data.desde)} – ${formatDate(data.hasta)}'),
          if (data.hasPrevious && data.anteriorDesde != null && data.anteriorHasta != null)
            TextSpan(text: ' · comparado con ${formatDate(data.anteriorDesde!)} – ${formatDate(data.anteriorHasta!)}'),
          if (cat != null) TextSpan(text: ' · categoría: $cat', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: const Column(
        children: [
          SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary)),
          SizedBox(height: 14),
          Text('Consultando la base de datos…', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _FullError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _FullError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 32, color: AppColors.textLight),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.35)),
          const SizedBox(height: 8),
          const Text(
            'Verifica que el backend de PlayApp esté encendido (start-playapp.bat en la carpeta backend) '
            'y que sea la versión actualizada del repositorio.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppColors.textLight, height: 1.35),
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
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12, color: AppColors.textMain))),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Se cuentan los productos vendidos en pedidos no cancelados. Ingresos = subtotal de cada producto. '
      'El periodo anterior tiene la misma duración que el seleccionado.',
      style: TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.35),
    );
  }
}
