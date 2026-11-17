import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/review_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/review_provider.dart';
import '../../widgets/custom_app_bar.dart';

class ReviewsContactScreen extends StatefulWidget {
  const ReviewsContactScreen({super.key});

  @override
  State<ReviewsContactScreen> createState() => _ReviewsContactScreenState();
}

class _ReviewsContactScreenState extends State<ReviewsContactScreen> {
  final _reviewFormKey = GlobalKey<FormState>();
  final _contactFormKey = GlobalKey<FormState>();

  final _reviewNameCtrl = TextEditingController();
  final _reviewCommentCtrl = TextEditingController();
  int _rating = 5;

  final _contactNameCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  String _contactSubject = 'Consulta sobre delivery en playa';
  final _contactMessageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      _reviewNameCtrl.text = user.nombre;
      _contactNameCtrl.text = user.nombre;
      _contactEmailCtrl.text = user.email;
    }
  }

  @override
  void dispose() {
    _reviewNameCtrl.dispose();
    _reviewCommentCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactEmailCtrl.dispose();
    _contactMessageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_reviewFormKey.currentState!.validate()) return;

    final prov = Provider.of<ReviewProvider>(context, listen: false);
    final success = await prov.addReview(
      nombre: _reviewNameCtrl.text,
      calificacion: _rating,
      comentario: _reviewCommentCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Gracias por tu reseña playera!'),
          backgroundColor: AppColors.success,
        ),
      );
      _reviewCommentCtrl.clear();
    }
  }

  Future<void> _submitContact() async {
    if (!_contactFormKey.currentState!.validate()) return;

    final prov = Provider.of<ReviewProvider>(context, listen: false);
    final success = await prov.sendContactMessage(
      nombre: _contactNameCtrl.text,
      email: _contactEmailCtrl.text,
      asunto: _contactSubject,
      mensaje: _contactMessageCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Mensaje enviado! Nos contactaremos a la brevedad.'),
          backgroundColor: AppColors.success,
        ),
      );
      _contactMessageCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewProv = Provider.of<ReviewProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Reseñas & Contacto'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: const [
                Icon(Icons.star, color: AppColors.warning, size: 20),
                SizedBox(width: 6),
                Text(
                  'EXPERIENCIAS DE CLIENTES EN PLAYA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Reseñas de PlayApp',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta: Deja tu Reseña
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sandBorder),
              ),
              child: Form(
                key: _reviewFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deja tu reseña',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _reviewNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tu Nombre',
                        hintText: 'Ingresa tu nombre',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                    ),
                    const SizedBox(height: 14),

                    // Selector de estrellas 1 a 5
                    Row(
                      children: [
                        const Text(
                          'Valoración: ',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(5, (index) {
                            final star = index + 1;
                            return IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              icon: Icon(
                                star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: AppColors.warning,
                                size: 28,
                              ),
                              onPressed: () => setState(() => _rating = star),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _reviewCommentCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Comentario',
                        hintText: 'Escribe tu opinión sobre el servicio o la comida en la playa...',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe tu opinión' : null,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: reviewProv.isLoading ? null : _submitReview,
                        child: const Text('Publicar Reseña'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Reseñas Recientes
            const Text(
              'Reseñas recientes en Cartagena',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 12),
            ...reviewProv.reviews.map((r) => _buildReviewCard(r)),
            const SizedBox(height: 32),

            // Sección de Contacto
            const Divider(height: 1),
            const SizedBox(height: 24),
            const Text(
              'Contáctanos & Soporte',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Estamos en las playas de Cartagena para ayudarte en cualquier momento.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),

            // Datos de contacto rápido
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sandBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.location_on, color: AppColors.coral, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Punto de Atención en Playa',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            Text(
                              'Cra. 1, Bocagrande, Cartagena de Indias (Kiosco El Bony)',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Icon(Icons.phone, color: AppColors.success, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Línea de Pedidos WhatsApp',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            Text(
                              '+57 323 254 2588 (Atención 8:00 AM - 7:00 PM)',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Formulario de Contacto
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sandBorder),
              ),
              child: Form(
                key: _contactFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Envíanos un mensaje',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Responderemos a tus consultas o reservas a la brevedad.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tu Nombre',
                        hintText: 'Tu nombre completo',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        hintText: 'tu@correo.com',
                      ),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Correo válido requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _contactSubject,
                      decoration: const InputDecoration(labelText: 'Asunto'),
                      items: const [
                        DropdownMenuItem(value: 'Consulta sobre delivery en playa', child: Text('Consulta sobre delivery')),
                        DropdownMenuItem(value: 'Reserva de carpas y servicios', child: Text('Reserva de carpas')),
                        DropdownMenuItem(value: 'Reporte de pago o factura', child: Text('Reporte de pago')),
                        DropdownMenuItem(value: 'Sugerencia o felicitación', child: Text('Sugerencia')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _contactSubject = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactMessageCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Mensaje',
                        hintText: 'Escribe tu mensaje o solicitud detallada...',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un mensaje' : null,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitContact,
                        child: const Text('Enviar Mensaje'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                r.nombreCliente,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.deepNavy),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < r.calificacion ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.warning,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            r.comentario,
            style: const TextStyle(fontSize: 13, color: AppColors.textMain, height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            r.fecha,
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
