import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../state/playapp_state.dart';
import '../theme/playapp_theme.dart';

/// Inicio de sesión y registro (`login.html`) con soporte de roles Usuario/Administrador.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  RolUsuario _selectedRole = RolUsuario.user;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMsg;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitLogin(PlayAppState state) async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final err = await state.loginAsync(
      correo: _emailCtrl.text,
      password: _passwordCtrl.text,
      rolEsperado: _selectedRole,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (err != null) {
      setState(() => _errorMsg = err);
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _submitRegister(PlayAppState state) async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final err = state.register(
      nombreCompleto: _nameCtrl.text,
      correo: _emailCtrl.text,
      password: _passwordCtrl.text,
      rol: _selectedRole,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (err != null) {
      setState(() => _errorMsg = err);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = PlayAppScope.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: Row(
          children: [
            Image.asset('assets/images/Logo_oficial.png', height: 26),
            const SizedBox(width: 8),
            const Text('PlayApp'),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/costa-de-isla-vista-aerea.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withValues(alpha: 0.65)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      const Text(
                        'PlayApp',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Evita estafas en las playas de Cartagena',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: PlayAppColors.darkCard.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            if (_errorMsg != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: PlayAppColors.dangerRed
                                      .withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _errorMsg!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                            TabBar(
                              controller: _tabController,
                              indicatorColor: PlayAppColors.primaryBlue,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white60,
                              onTap: (_) => setState(() => _errorMsg = null),
                              tabs: const [
                                Tab(text: 'Iniciar Sesión'),
                                Tab(text: 'Registrarse'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<RolUsuario>(
                              initialValue: _selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'Ingresar / Registrar como',
                              ),
                              items: RolUsuario.values.map((r) {
                                return DropdownMenuItem(
                                  value: r,
                                  child: Text(r.etiqueta),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedRole = val);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            AnimatedBuilder(
                              animation: _tabController,
                              builder: (context, _) {
                                final isRegister = _tabController.index == 1;
                                return Column(
                                  children: [
                                    if (isRegister) ...[
                                      TextField(
                                        controller: _nameCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Nombre Completo',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    TextField(
                                      controller: _emailCtrl,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Correo electrónico',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _passwordCtrl,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        labelText: 'Contraseña',
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () => isRegister
                                                ? _submitRegister(state)
                                                : _submitLogin(state),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                isRegister
                                                    ? 'Registrarse'
                                                    : 'Ingresar',
                                              ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const Divider(color: Colors.white24, height: 26),
                            const Text(
                              'Acceso rápido demo (para pruebas)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      state.loginDemo(RolUsuario.user);
                                      Navigator.of(context).pop();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: PlayAppColors.accentSky,
                                      side: const BorderSide(
                                        color: PlayAppColors.accentSky,
                                      ),
                                    ),
                                    child: const Text('Demo Usuario'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      state.loginDemo(RolUsuario.admin);
                                      Navigator.of(context).pop();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.amberAccent,
                                      side: const BorderSide(
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                    child: const Text('Demo Admin'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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
