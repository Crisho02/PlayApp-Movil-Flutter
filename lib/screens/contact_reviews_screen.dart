import 'package:flutter/material.dart';
import '../models/resena.dart';
import '../state/playapp_state.dart';
import '../theme/playapp_theme.dart';

/// Reseñas y Contacto (`contacto.html`).
class ContactReviewsScreen extends StatefulWidget {
  const ContactReviewsScreen({super.key});

  @override
  State<ContactReviewsScreen> createState() => _ContactReviewsScreenState();
}

class _ContactReviewsScreenState extends State<ContactReviewsScreen> {
  final _reviewNameCtrl = TextEditingController();
  final _reviewCommentCtrl = TextEditingController();
  int _rating = 5;

  final _contactNameCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _contactMsgCtrl = TextEditingController();
  String _asunto = 'reserva';

  @override
  void dispose() {
    _reviewNameCtrl.dispose();
    _reviewCommentCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactEmailCtrl.dispose();
    _contactMsgCtrl.dispose();
    super.dispose();
  }

  void _submitReview(PlayAppState state) {
    final name = _reviewNameCtrl.text.trim();
    final comment = _reviewCommentCtrl.text.trim();
    if (name.isEmpty || comment.isEmpty) {
      _showBanner('Completa tu nombre y comentario para publicar la reseña.', isError: true);
      return;
    }
    state.agregarResena(
      nombre: name,
      valoracion: _rating,
      comentario: comment,
    );
    _reviewNameCtrl.clear();
    _reviewCommentCtrl.clear();
    setState(() => _rating = 5);
    _showBanner('¡Gracias! Tu reseña fue publicada.');
  }

  void _submitContact(PlayAppState state) {
    final name = _contactNameCtrl.text.trim();
    final email = _contactEmailCtrl.text.trim();
    final msg = _contactMsgCtrl.text.trim();
    if (name.isEmpty || email.isEmpty || msg.isEmpty) {
      _showBanner('Completa nombre, correo y mensaje.', isError: true);
      return;
    }
    state.enviarMensajeContacto(
      nombre: name,
      email: email,
      asunto: _asunto,
      mensaje: msg,
    );
    _contactNameCtrl.clear();
    _contactEmailCtrl.clear();
    _contactMsgCtrl.clear();
    _showBanner('✓ Mensaje enviado correctamente.');
  }

  void _showBanner(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor:
              isError ? PlayAppColors.dangerRed : PlayAppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = PlayAppScope.of(context);
    final resenas = state.resenas;

    return ColoredBox(
      color: PlayAppColors.darkSurface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 95),
        children: [
          _buildReviewsSection(state, resenas),
          const SizedBox(height: 18),
          _buildContactSection(state),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(PlayAppState state, List<Resena> resenas) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PlayAppColors.darkCard.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Reseñas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Deja tu reseña',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reviewNameCtrl,
            decoration: const InputDecoration(hintText: 'Tu nombre'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Valoración:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 8),
              ...List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFD700),
                    size: 28,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reviewCommentCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Cuéntanos tu experiencia en la playa...',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submitReview(state),
              child: const Text('Enviar Reseña'),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Reseñas recientes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...resenas.take(4).map((r) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        '★' * r.valoracion,
                        style: const TextStyle(
                          color: Color(0xFFEAB308),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.comentario,
                    style: const TextStyle(color: Color(0xFF374151)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContactSection(PlayAppState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PlayAppColors.darkCard.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Contáctanos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Estamos aquí para ayudarte. Envíanos un mensaje o visítanos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.location_on,
                  title: 'Dirección',
                  body: 'Cra. 1, Cartagena de Indias\nBolívar - Kiosco El Bony',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoCard(
                  icon: Icons.phone,
                  title: 'Teléfono',
                  body: '+57 323 254 5463',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/costa-de-isla-vista-aerea.jpg',
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _contactNameCtrl,
            decoration: const InputDecoration(hintText: 'Nombre'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _contactEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Email'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _asunto,
            decoration: const InputDecoration(labelText: 'Asunto'),
            items: const [
              DropdownMenuItem(value: 'reserva', child: Text('Reservación')),
              DropdownMenuItem(value: 'consulta', child: Text('Consulta')),
              DropdownMenuItem(value: 'sugerencia', child: Text('Sugerencia')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _asunto = val);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _contactMsgCtrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Mensaje'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submitContact(state),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
              ),
              child: const Text('Enviar Mensaje'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: PlayAppColors.primaryBlue),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }
}
