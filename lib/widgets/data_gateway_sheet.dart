import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/data_gateway.dart';
import '../state/playapp_state.dart';
import '../theme/playapp_theme.dart';

/// Modal informativo y de control para la Pasarela de Datos y MongoDB Atlas.
class DataGatewaySheet extends StatelessWidget {
  const DataGatewaySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = PlayAppScope.of(context);
    final isConnected = state.isDatabaseConnected;
    final status = state.gatewayStatus;
    final stats = state.dbStats;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PlayAppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.storage,
                  color: PlayAppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pasarela de Datos · PlayApp',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Base de Datos: MongoDB Atlas (playappdb)',
                      style: TextStyle(
                        fontSize: 12,
                        color: PlayAppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Estado de Conexión
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConnected
                  ? PlayAppColors.successGreen.withValues(alpha: 0.12)
                  : (status == GatewayStatus.conectando
                      ? PlayAppColors.warningAmber.withValues(alpha: 0.14)
                      : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isConnected
                    ? PlayAppColors.successGreen
                    : (status == GatewayStatus.conectando
                        ? PlayAppColors.warningAmber
                        : const Color(0xFFD1D5DB)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isConnected
                      ? Icons.cloud_done
                      : (status == GatewayStatus.conectando
                          ? Icons.cloud_sync
                          : Icons.cloud_off),
                  color: isConnected
                      ? PlayAppColors.successGreen
                      : (status == GatewayStatus.conectando
                          ? PlayAppColors.warningAmber
                          : PlayAppColors.mutedText),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.etiqueta,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isConnected
                              ? const Color(0xFF14532D)
                              : Colors.black87,
                        ),
                      ),
                      Text(
                        isConnected
                            ? 'Sincronizado en tiempo real con el proyecto universitario.'
                            : 'Modo seguro local con persistencia reactiva en memoria.',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: PlayAppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (kIsWeb) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: Color(0xFFB45309)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estás ejecutando en Flutter Web (Chrome). Por seguridad, los navegadores no permiten abrir sockets TCP directos (puerto 27017) hacia MongoDB Atlas. Para conectar con la base de datos real en vivo, ejecuta en Android o en Windows Desktop (`flutter run -d windows`).',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Detalle de Colecciones
          const Text(
            'Colecciones sincronizadas en MongoDB:',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: [
              _CollectionStatCard(
                collection: 'productos',
                count: stats['productos'] ?? state.productos.length,
                icon: Icons.inventory_2_outlined,
              ),
              _CollectionStatCard(
                collection: 'pedidos',
                count: stats['pedidos'] ?? state.pedidos.length,
                icon: Icons.receipt_long_outlined,
              ),
              _CollectionStatCard(
                collection: 'entidades',
                count: stats['entidades'] ?? 33,
                icon: Icons.people_outline,
              ),
              _CollectionStatCard(
                collection: 'reseñas',
                count: stats['reseñas'] ?? state.resenas.length,
                icon: Icons.star_outline,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botón de sincronización manual
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.isSyncing
                  ? null
                  : () async {
                      await state.sincronizarConBaseDeDatos();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              state.isDatabaseConnected
                                  ? '¡Datos sincronizados exitosamente con MongoDB Atlas!'
                                  : 'No se pudo contactar con MongoDB Atlas. Se mantienen datos locales.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              icon: state.isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync),
              label: Text(
                state.isSyncing
                    ? 'Sincronizando...'
                    : 'Sincronizar ahora con MongoDB Atlas',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionStatCard extends StatelessWidget {
  const _CollectionStatCard({
    required this.collection,
    required this.count,
    required this.icon,
  });

  final String collection;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: PlayAppColors.primaryBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  collection,
                  style: const TextStyle(
                    fontSize: 11,
                    color: PlayAppColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$count docs',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
