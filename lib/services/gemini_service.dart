import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/pedido.dart';
import '../models/producto.dart';
import 'chat_bot_service.dart';

/// Servicio de Inteligencia Artificial para el Asistente PlayApp.
/// Integra Google Gemini REST API (idéntico a `GeminiService.java` de PlayApp)
/// y recurre al motor de intenciones costeras cuando no hay conexión.
class PlayAppGeminiService {
  PlayAppGeminiService({
    this.apiKey = 'AIzaSyCUMgBWjkp_IJZrTO4RjiSiThUqWmsOZnE',
    this.model = 'gemini-1.5-flash',
    this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta',
  });

  final String apiKey;
  final String model;
  final String baseUrl;

  /// Envía la consulta a Gemini con el contexto de precios y catálogo de PlayApp.
  Future<String> responder({
    required String mensaje,
    required List<Producto> productos,
    required List<Pedido> pedidos,
    required int itemsEnCarrito,
    required String? usuarioNombre,
  }) async {
    // Si no hay API Key o falla, usamos el motor local
    if (apiKey.isEmpty) {
      return ChatBotService.responder(
        mensaje: mensaje,
        productos: productos,
        pedidos: pedidos,
        itemsEnCarrito: itemsEnCarrito,
        usuarioNombre: usuarioNombre,
      );
    }

    try {
      final contextPrompt = _buildContextPrompt(
        productos: productos,
        pedidos: pedidos,
        itemsEnCarrito: itemsEnCarrito,
        usuarioNombre: usuarioNombre,
      );

      final url = Uri.parse(
        '$baseUrl/models/$model:generateContent?key=$apiKey',
      );

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {
                      'text': '$contextPrompt\n\nPregunta del usuario en playa: "$mensaje"',
                    }
                  ],
                }
              ],
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 300,
              },
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text']?.toString().trim();
            if (text != null && text.isNotEmpty) {
              return text;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[PlayAppGeminiService] Error llamando a Gemini, recurriendo a modo local: $e');
    }

    // Fallback al motor local determinista
    return ChatBotService.responder(
      mensaje: mensaje,
      productos: productos,
      pedidos: pedidos,
      itemsEnCarrito: itemsEnCarrito,
      usuarioNombre: usuarioNombre,
    );
  }

  String _buildContextPrompt({
    required List<Producto> productos,
    required List<Pedido> pedidos,
    required int itemsEnCarrito,
    required String? usuarioNombre,
  }) {
    final prodsBrief = productos
        .take(8)
        .map((p) => '- ${p.nombre} (${p.categoria.etiqueta}): \$${p.precio.toStringAsFixed(0)} COP (Stock: ${p.stock})')
        .join('\n');

    return '''
Eres el Asistente Inteligente oficial de PlayApp, una aplicación móvil desarrollada para turistas y bañistas en las playas de Cartagena de Indias, Colombia (Bocagrande, Castillogrande, Marbella, Laguito, Playa Blanca).
Tu objetivo principal es proteger al turista de estafas y sobrecostos, informar sobre precios justos oficiales, recomendar platos caribeños típicos (mojarra, pescado frito, ceviche, arroz de coco) y bebidas frías (limonada de coco, coco frío, cerveza), y guiar en el estado de sus pedidos.

Usuario actual: ${usuarioNombre ?? "Visitante"}
Items en carrito: $itemsEnCarrito
Catálogo en tiempo real:
$prodsBrief

Responde de manera amable, costeña y concisa (máximo 3 párrafos cortos). Si preguntan por precios de productos en el catálogo, usa los valores en COP.
''';
  }
}
