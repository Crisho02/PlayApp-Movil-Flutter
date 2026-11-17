import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/env_config.dart';
import '../constants/app_constants.dart';

class ImageHelper {
  /// Construye una URL completa a partir de una ruta del backend
  static String buildImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = EnvConfig.apiBaseUrl;
    if (trimmed.startsWith('/')) {
      return '$base$trimmed';
    }
    return '$base/$trimmed';
  }

  /// Retorna la URL del endpoint de imagen para un producto por su ID
  static String productImageUrl(String productId) {
    if (productId.isEmpty) return '';
    return '${EnvConfig.apiBaseUrl}/api/products/$productId/image';
  }

  /// Construye un widget de imagen robusto, elegante y responsive
  static Widget buildProductImage({
    String? imageSrc,
    String? imageUrl,
    String? productId,
    String? assetFallback,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    // 1. Verificar si es una cadena Base64 (data:image/...;base64,...)
    if (imageSrc != null && imageSrc.contains('base64,')) {
      try {
        final cleanBase64 = imageSrc.split('base64,').last.trim();
        final bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => _buildAssetOrPlaceholder(assetFallback, fit, width, height),
        );
      } catch (_) {}
    }

    // 2. Determinar la URL del servidor
    String targetUrl = '';
    if (imageUrl != null && imageUrl.isNotEmpty) {
      targetUrl = buildImageUrl(imageUrl);
    } else if (productId != null && productId.isNotEmpty) {
      targetUrl = productImageUrl(productId);
    } else if (imageSrc != null && (imageSrc.startsWith('http') || imageSrc.startsWith('/'))) {
      targetUrl = buildImageUrl(imageSrc);
    }

    // 3. Cargar desde la red con placeholder elegante y respaldo limpio
    if (targetUrl.isNotEmpty) {
      return Image.network(
        targetUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppColors.sandBackground,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.turquoise,
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) {
          // Si falla la carga del servidor, mostrar el recurso local o placeholder elegante sin texto técnico
          return _buildAssetOrPlaceholder(assetFallback, fit, width, height);
        },
      );
    }

    // 4. Recurso local o placeholder
    return _buildAssetOrPlaceholder(assetFallback, fit, width, height);
  }

  static Widget _buildAssetOrPlaceholder(String? assetPath, BoxFit fit, double? width, double? height) {
    if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _buildDefaultPlaceholder(width, height),
      );
    }
    return _buildDefaultPlaceholder(width, height);
  }

  static Widget _buildDefaultPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: AppColors.sandBackground,
      child: const Center(
        child: Icon(
          Icons.restaurant_outlined,
          color: AppColors.textLight,
          size: 32,
        ),
      ),
    );
  }
}
