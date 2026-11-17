import 'package:flutter/material.dart';

class AppColors {
  // Brand Ocean / Sky
  static const Color primary = Color(0xFF0284C7);
  static const Color primaryDark = Color(0xFF075985);
  static const Color deepNavy = Color(0xFF0C4A6E);
  static const Color turquoise = Color(0xFF14B8A6);
  static const Color turquoiseLight = Color(0xFFCCFBF1);

  // Sand / Beach Warm Neutrals
  static const Color sandBackground = Color(0xFFF8F5EF);
  static const Color sandBorder = Color(0xFFE7DEC8);
  static const Color surfaceWhite = Colors.white;

  // Accents & Badges
  static const Color coral = Color(0xFFF97360);
  static const Color coralSoft = Color(0xFFFFECE8);
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEE2E2);

  // Text
  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
}

class AppAssets {
  static const String logo = 'assets/images/Logo.png';
  static const String logoOficial = 'assets/images/Logo_oficial.png';
  static const String burger = 'assets/images/Burguer.jpg';
  static const String pescado = 'assets/images/Pescado.jpg';
  static const String bebidas = 'assets/images/Bebidas.jpeg';
  static const String placeholder = 'assets/images/blank-product.jpg';
  static const String langosta = 'assets/images/Langosta.png';
  static const String bebidaPng = 'assets/images/Bebida.png';
  static const String moto = 'assets/images/Moto.png';
  static const String costaAerea = 'assets/images/costa-de-isla-vista-aerea.jpg';
  static const String arenaDemas = 'assets/images/ArenaDemas.jpg';
}

class OrderStatusConstants {
  static const String recibido = 'Recibido';
  static const String enPreparacion = 'En preparación';
  static const String terminado = 'Terminado';
  static const String cancelado = 'Cancelado';
}

class PaymentStatusConstants {
  static const String pagado = 'Pagado';
  static const String aprobado = 'Aprobado';
  static const String iniciado = 'Iniciado';
  static const String rechazado = 'Rechazado';
  static const String pendienteContraentrega = 'Pendiente contraentrega';
}

class PaymentMethodConstants {
  static const String wompi = 'WOMPI';
  static const String efectivo = 'EFECTIVO_CONTRAENTREGA';
  static const String transferencia = 'TRANSFERENCIA_CONTRAENTREGA';
}
