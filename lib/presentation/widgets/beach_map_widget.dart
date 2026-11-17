import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';

class BeachMapWidget extends StatefulWidget {
  final String selectedZone;
  final ValueChanged<String> onZoneChanged;
  final TextEditingController carpaController;
  final TextEditingController notesController;
  final TextEditingController? addressController;
  final void Function(double lat, double lng)? onLocationChanged;

  const BeachMapWidget({
    super.key,
    required this.selectedZone,
    required this.onZoneChanged,
    required this.carpaController,
    required this.notesController,
    this.addressController,
    this.onLocationChanged,
  });

  @override
  State<BeachMapWidget> createState() => _BeachMapWidgetState();
}

class _BeachMapWidgetState extends State<BeachMapWidget> {
  late final MapController _mapController;

  // Coordenadas base reales de la versión web de PlayApp (Bocagrande, Cartagena)
  static const LatLng _bocagrandeCentral = LatLng(10.394598592365298, -75.5571199005398);

  late LatLng _selectedLocation;

  final List<Map<String, dynamic>> _zones = [
    {
      'name': 'Bocagrande (Kiosco El Bony)',
      'desc': 'Cra. 1 frente a Kiosco El Bony',
      'lat': 10.3997,
      'lng': -75.5562,
      'badge': 'Más Popular',
    },
    {
      'name': 'Bocagrande Central (Hotel Caribe)',
      'desc': 'Cra. 2 frente a carpas y espolón',
      'lat': 10.3946,
      'lng': -75.5571,
      'badge': 'Zona Central',
    },
    {
      'name': 'El Laguito (Hotel Hilton)',
      'desc': 'Espolón y playas del Hotel Hilton',
      'lat': 10.3955,
      'lng': -75.5620,
      'badge': 'Espolón',
    },
    {
      'name': 'Castillogrande (Bahía)',
      'desc': 'Paseo peatonal y aguas calmas',
      'lat': 10.3920,
      'lng': -75.5510,
      'badge': 'Tranquila',
    },
    {
      'name': 'Marbella / Cabrero',
      'desc': 'Cerca a letras gigantes de Cartagena',
      'lat': 10.4350,
      'lng': -75.5410,
      'badge': 'Norte',
    },
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = _findCoordsForZone(widget.selectedZone) ?? _bocagrandeCentral;
  }

  LatLng? _findCoordsForZone(String zoneName) {
    for (final z in _zones) {
      if (z['name'] == zoneName) {
        return LatLng(z['lat'] as double, z['lng'] as double);
      }
    }
    return null;
  }

  void _onZoneSelected(Map<String, dynamic> zone) {
    final lat = zone['lat'] as double;
    final lng = zone['lng'] as double;
    final target = LatLng(lat, lng);

    setState(() {
      _selectedLocation = target;
    });

    _mapController.move(target, 16.0);
    widget.onZoneChanged(zone['name'] as String);
    widget.onLocationChanged?.call(lat, lng);

    if (widget.addressController != null && widget.addressController!.text.isEmpty) {
      widget.addressController!.text = 'Sector ${zone['name']}';
    }
  }

  void _onMapTapped(LatLng point) {
    setState(() {
      _selectedLocation = point;
    });

    widget.onLocationChanged?.call(point.latitude, point.longitude);

    if (widget.addressController != null) {
      widget.addressController!.text =
          'Playa Bocagrande (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
    }
  }

  void _zoomIn() {
    final zoom = _mapController.camera.zoom;
    if (zoom < 18) {
      _mapController.move(_selectedLocation, zoom + 1);
    }
  }

  void _zoomOut() {
    final zoom = _mapController.camera.zoom;
    if (zoom > 12) {
      _mapController.move(_selectedLocation, zoom - 1);
    }
  }

  void _recenterBocagrande() {
    setState(() {
      _selectedLocation = _bocagrandeCentral;
    });
    _mapController.move(_bocagrandeCentral, 16.0);
    widget.onLocationChanged?.call(_bocagrandeCentral.latitude, _bocagrandeCentral.longitude);
  }

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
            'Toca en el mapa de Bocagrande para marcar tu carpa, toalla o sector exacto en la playa.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 14),

          // Mapa interactivo real de Bocagrande con OpenStreetMap
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sandBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 16.0,
                    minZoom: 12.0,
                    maxZoom: 18.0,
                    onTap: (tapPosition, point) => _onMapTapped(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.playapp.cartagena',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.coral,
                            size: 44,
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black38),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Controles flotantes de zoom y recentrado
                Positioned(
                  top: 10,
                  right: 10,
                  child: Column(
                    children: [
                      _buildFloatingMapButton(
                        icon: Icons.add,
                        tooltip: 'Acercar',
                        onTap: _zoomIn,
                      ),
                      const SizedBox(height: 6),
                      _buildFloatingMapButton(
                        icon: Icons.remove,
                        tooltip: 'Alejar',
                        onTap: _zoomOut,
                      ),
                      const SizedBox(height: 6),
                      _buildFloatingMapButton(
                        icon: Icons.my_location,
                        tooltip: 'Centrar Bocagrande',
                        onTap: _recenterBocagrande,
                      ),
                    ],
                  ),
                ),

                // Chip de coordenadas seleccionadas
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.deepNavy.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pin_drop, color: AppColors.turquoise, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Atribución oficial OpenStreetMap
                Positioned(
                  bottom: 4,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '© OpenStreetMap contributors',
                      style: TextStyle(fontSize: 9, color: Colors.black54),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Selector rápido de playas en Cartagena
          const Text(
            'Sectores habilitados en Bocagrande y playas:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
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
                  onTap: () => _onZoneSelected(zone),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.turquoiseLight.withOpacity(0.4)
                          : AppColors.sandBackground,
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

          // Número de Carpa / Mesa y Referencia / Toalla
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
                    hintText: 'Ej: Carpas azules, toalla roja',
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

  Widget _buildFloatingMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 18, color: AppColors.deepNavy),
        ),
      ),
    );
  }
}
