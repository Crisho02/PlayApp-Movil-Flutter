import 'package:flutter/material.dart';

/// Colores y utilidades de formato de marca para PlayApp.
class PlayAppColors {
  PlayAppColors._();

  static const Color darkSurface = Color(0xFF0E121A);
  static const Color darkHeader = Color(0xFF1A1F29);
  static const Color darkCard = Color(0xFF212529);
  static const Color primaryBlue = Color(0xFF0D6EFD);
  static const Color accentSky = Color(0xFF4DA6FF);
  static const Color backgroundGrey = Color(0xFFF6F6F6);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color mutedText = Color(0xFF64748B);

  static const Color successGreen = Color(0xFF198754);
  static const Color warningAmber = Color(0xFFFFC107);
  static const Color dangerRed = Color(0xFFDC3545);
  static const Color infoCyan = Color(0xFF0DCAF0);

  // Paleta del Asistente PlayApp (chat-widget.css)
  static const Color chatHeaderStart = Color(0xFF075E54);
  static const Color chatHeaderEnd = Color(0xFF0B6C61);
  static const Color chatSendGreen = Color(0xFF00A884);
  static const Color chatBackground = Color(0xFFE5DDD5);
  static const Color chatUserBubble = Color(0xFFDCF8C6);
}

/// Tema principal de PlayApp basado en su paleta costera y Bootstrap dark/light.
ThemeData buildPlayAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: PlayAppColors.primaryBlue,
    primary: PlayAppColors.primaryBlue,
    secondary: PlayAppColors.accentSky,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: PlayAppColors.backgroundGrey,
    appBarTheme: const AppBarTheme(
      backgroundColor: PlayAppColors.darkHeader,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: PlayAppColors.cardBorder, width: 0.7),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: PlayAppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: PlayAppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: PlayAppColors.primaryBlue, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PlayAppColors.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

/// Formatea valores numéricos en pesos colombianos (ej. `$32.000`).
String formatCop(double? value) {
  if (value == null) return '\$0';
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final posFromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }
  final prefix = rounded < 0 ? '-\$' : '\$';
  return '$prefix$buffer';
}

/// Formatea una fecha `DateTime` como `dd-MM-yyyy HH:mm`.
String formatDateTime(DateTime dateTime) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dateTime.day)}-${two(dateTime.month)}-${dateTime.year} '
      '${two(dateTime.hour)}:${two(dateTime.minute)}';
}
