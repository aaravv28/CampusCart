import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Robust, cross-platform image widget that safely handles nulls, local file paths,
/// memory bytes, base64 data URIs, remote network URLs, loading states, and offline failures
/// across Web, Android, iOS, and Desktop without throwing exceptions.
class SafeItemImage extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? category;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;

  const SafeItemImage({
    super.key,
    this.imageUrl,
    this.imageBytes,
    this.category,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholderIcon = Icons.inventory_2_outlined,
  });

  IconData _resolvePlaceholderIcon() {
    if (placeholderIcon != Icons.inventory_2_outlined) {
      return placeholderIcon;
    }
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('textbook') || cat.contains('book')) {
      return Icons.menu_book_rounded;
    }
    if (cat.contains('electronic') ||
        cat.contains('calc') ||
        cat.contains('tech')) {
      return Icons.devices_rounded;
    }
    if (cat.contains('dorm') || cat.contains('furniture')) {
      return Icons.chair_rounded;
    }
    if (cat.contains('lab')) {
      return Icons.biotech_rounded;
    }
    return Icons.inventory_2_outlined;
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // 1. Direct memory bytes (works on ALL platforms including Web & Android)
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      imageWidget = Image.memory(
        imageBytes!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      final url = imageUrl?.trim();

      if (url == null || url.isEmpty) {
        imageWidget = _buildPlaceholder();
      } else if (url.startsWith('data:image')) {
        // Base64 data URI
        try {
          final commaIndex = url.indexOf(',');
          final base64String = commaIndex != -1
              ? url.substring(commaIndex + 1)
              : url;
          final bytes = base64Decode(base64String);
          imageWidget = Image.memory(
            bytes,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          );
        } catch (_) {
          imageWidget = _buildPlaceholder();
        }
      } else if (kIsWeb) {
        // On Web: Network URLs, blob URLs, and relative paths work with Image.network
        imageWidget = Image.network(
          url,
          fit: fit,
          width: width,
          height: height,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoading();
          },
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } else {
        // Mobile / Desktop native platform
        if (_isLocalFilePath(url)) {
          try {
            final file = File(url);
            if (file.existsSync()) {
              imageWidget = Image.file(
                file,
                fit: fit,
                width: width,
                height: height,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(),
              );
            } else {
              imageWidget = _buildPlaceholder();
            }
          } catch (_) {
            imageWidget = _buildPlaceholder();
          }
        } else {
          imageWidget = Image.network(
            url,
            fit: fit,
            width: width,
            height: height,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoading();
            },
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          );
        }
      }
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  bool _isLocalFilePath(String path) {
    return path.startsWith('/') ||
        path.contains(':\\') ||
        path.contains(':/') ||
        path.startsWith('file:');
  }

  Widget _buildLoading() {
    return Container(
      color: Colors.grey.shade100,
      width: width,
      height: height,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryIris,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final icon = _resolvePlaceholderIcon();
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppTheme.primaryLight),
      child: Center(
        child: Icon(
          icon,
          size: (height != null && height! < 60) ? 24 : 42,
          color: AppTheme.primaryIris.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
