import 'package:flutter/material.dart';

/// Etiqueta tipo pill de Bootstrap para categorías y estados de pedido/pago.
class PlayAppPillBadge extends StatelessWidget {
  const PlayAppPillBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    this.textColor = Colors.white,
    this.fontSize = 11.5,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}
