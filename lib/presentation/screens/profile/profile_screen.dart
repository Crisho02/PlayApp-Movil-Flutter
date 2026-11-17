import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/custom_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir de tu cuenta de PlayApp?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Perfil de Usuario'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Tarjeta de Usuario
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.sandBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: user != null
                  ? Column(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: AppColors.primaryDark,
                          child: Text(
                            user.nombre.isNotEmpty ? user.nombre.substring(0, 1).toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          user.nombre,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepNavy,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: user.isAdmin ? AppColors.coralSoft : AppColors.turquoiseLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.isAdmin ? 'ADMINISTRADOR PLAYAPP' : 'CLIENTE CARTAGENA',
                            style: TextStyle(
                              color: user.isAdmin ? AppColors.coral : AppColors.turquoise,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Divider(height: 1),
                        const SizedBox(height: 14),

                        // Datos de entrega
                        if (user.telefono != null && user.telefono!.isNotEmpty)
                          _buildInfoRow(Icons.phone_outlined, 'Teléfono', user.telefono!),
                        if (user.direccion != null && user.direccion!.isNotEmpty)
                          _buildInfoRow(Icons.location_on_outlined, 'Sector Playa', user.direccion!),
                        if (user.mesa != null)
                          _buildInfoRow(Icons.table_restaurant_outlined, 'Carpa Habitual', '#${user.mesa}'),

                        const SizedBox(height: 20),

                        // Botón de Panel Administrativo (solo si es administrador)
                        if (user.isAdmin) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepNavy),
                              onPressed: () {
                                Navigator.pushNamed(context, '/admin');
                              },
                              icon: const Icon(Icons.admin_panel_settings, size: 20),
                              label: const Text('Abrir Panel de Administración'),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Botón Cerrar Sesión
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.danger),
                              foregroundColor: AppColors.danger,
                            ),
                            onPressed: () => _confirmLogout(context),
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('Cerrar Sesión'),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Icon(Icons.account_circle_outlined, size: 68, color: AppColors.textLight),
                        const SizedBox(height: 14),
                        const Text(
                          'Bienvenido a PlayApp',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Inicia sesión para sincronizar tus pedidos en la playa y disfrutar de precios verificados.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, '/login'),
                                child: const Text('Iniciar Sesión'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pushNamed(context, '/register'),
                                child: const Text('Registrarse'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 32),

            // Footer informativo
            const Center(
              child: Text(
                'PlayApp Cartagena • Delivery en la orilla del mar',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
