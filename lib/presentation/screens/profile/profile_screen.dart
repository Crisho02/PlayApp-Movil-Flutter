import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/env_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/session_manager.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/custom_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _urlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlCtrl.text = EnvConfig.apiBaseUrl;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateServerUrl() async {
    final newUrl = _urlCtrl.text.trim();
    if (newUrl.isNotEmpty) {
      await SessionManager.setBaseUrl(newUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Servidor actualizado a: $newUrl'),
          backgroundColor: AppColors.primaryDark,
        ),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir de tu cuenta?'),
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
      appBar: const CustomAppBar(title: 'Perfil y Configuración'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Tarjeta de Usuario
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.sandBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: user != null
                  ? Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primaryDark,
                          child: Text(
                            user.nombre.isNotEmpty ? user.nombre.substring(0, 1).toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepNavy,
                          ),
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
                            user.isAdmin ? 'ADMINISTRADOR PLAYAPP' : 'CLIENTE PLAYA CARTAGENA',
                            style: TextStyle(
                              color: user.isAdmin ? AppColors.coral : AppColors.turquoise,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Datos adicionales
                        if (user.telefono != null && user.telefono!.isNotEmpty)
                          _buildInfoRow(Icons.phone_outlined, 'Teléfono', user.telefono!),
                        if (user.direccion != null && user.direccion!.isNotEmpty)
                          _buildInfoRow(Icons.location_on_outlined, 'Playa Favorita', user.direccion!),
                        if (user.mesa != null)
                          _buildInfoRow(Icons.table_restaurant_outlined, 'Carpa Habitual', '#${user.mesa}'),

                        const SizedBox(height: 16),

                        // Botón de Admin (si es administrador)
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
                            onPressed: _confirmLogout,
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('Cerrar Sesión'),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Icon(Icons.account_circle_outlined, size: 64, color: AppColors.textLight),
                        const SizedBox(height: 12),
                        const Text(
                          'Bienvenido a PlayApp',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Inicia sesión para sincronizar tus pedidos en la playa y acceder a beneficios.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 18),
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
            const SizedBox(height: 24),

            // Configuración del Servidor Backend
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.sandBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.dns_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Conexión del Backend Spring Boot',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Puedes ajustar la URL base para conectar con el backend local en emulador Android o tu red Wi-Fi:',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlCtrl,
                          decoration: const InputDecoration(
                            hintText: 'http://10.0.2.2:8080',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _updateServerUrl,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                        child: const Text('Guardar', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('Emulador Android (10.0.2.2)', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          _urlCtrl.text = 'http://10.0.2.2:8080';
                          _updateServerUrl();
                        },
                      ),
                      ActionChip(
                        label: const Text('Localhost (8080)', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          _urlCtrl.text = 'http://localhost:8080';
                          _updateServerUrl();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Versión y créditos
            const Center(
              child: Text(
                'PlayApp Móvil Cartagena • v1.0.0 (Flutter)',
                style: TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textLight),
          const SizedBox(width: 8),
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
