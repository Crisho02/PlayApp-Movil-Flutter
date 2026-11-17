import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class BeachMapWidget extends StatefulWidget {
  final String selectedZone;
  final ValueChanged<String> onZoneChanged;
  final TextEditingController carpaController;
  final TextEditingController notesController;

  const BeachMapWidget({
    super.key,
    required this.selectedZone,
    required this.onZoneChanged,
    required this.carpaController,
    required this.notesController,
  });

  @override
  State<BeachMapWidget> createState() => _BeachMapWidgetState();
}

class _BeachMapWidgetState extends State<BeachMapWidget> {
  final List<Map<String, dynamic>> _zones = [
    {
      'name': 'Bocagrande (Kiosco El Bony)',
      'desc': 'Frente a las carpas principales de la Cra. 1',
      'lat': 10.3997,
      'lng': -75.5562,
      'badge': 'Zona Más Rápida',
    },
    {
      'name': 'Castillogrande (Bahía)',
      'desc': 'Frente al paseo peatonal y muelle',
      'lat': 10.3920,
      'lng': -75.5510,
      'badge': 'Aguas Calmas',
    },
    {
      'name': 'El Laguito (Hotel Hilton)',
      'desc': 'Playas y espolón del Hotel Hilton',
      'lat': 10.3955,
      'lng': -75.5620,
      'badge': 'Espolón',
    },
    {
      'name': 'Marbella / Cabrero',
      'desc': 'Cerca a las letras de Cartagena',
      'lat': 10.4350,
      'lng': -75.5410,
      'badge': 'Norte',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: const [
              Icon(Icons.beach_access, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'Zona de Entrega en Playa',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.deepNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Llevamos tu pedido directamente a la carpa o toalla donde estés descansando.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 14),

          // Mapa interactivo visual representativo de Cartagena
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sandBorder),
              image: const DecorationImage(
                image: AssetImage(AppAssets.costaAerea),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.turquoise,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Radar Playa PlayApp Activo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(Icons.my_location, color: Colors.white, size: 20),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.coral, size: 24),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.selectedZone,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Selector de playas en Cartagena
          const Text(
            'Selecciona tu sector:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: _zones.map((zone) {
              final isSelected = widget.selectedZone == zone['name'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => widget.onZoneChanged(zone['name']),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.turquoiseLight.withOpacity(0.4) : AppColors.sandBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.turquoise : AppColors.sandBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppColors.primaryDark : AppColors.textLight,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                zone['name'],
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textMain,
                                ),
                              ),
                              Text(
                                zone['desc'],
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.sandBorder),
                          ),
                          child: Text(
                            zone['badge'],
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Número de Carpa / Mesa y Notas de Entrega
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: widget.carpaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'N° Carpa / Mesa',
                    hintText: 'Ej: 14',
                    prefixIcon: Icon(Icons.table_restaurant_outlined, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: widget.notesController,
                  decoration: const InputDecoration(
                    labelText: 'Referencia / Toalla',
                    hintText: 'Ej: Sombrilla azul',
                    prefixIcon: Icon(Icons.flag_outlined, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
