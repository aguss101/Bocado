import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/App.dart';
import '../theme/Notifier.dart';

/// Imagen de red con caché en disco + memoria (cached_network_image).
/// Reemplaza a `Image.network`: evita redescargas en cada scroll/navegación.
/// `memCacheWidth` limita la resolución decodificada en RAM (pasar el ancho
/// aprox. en px del display para miniaturas; omitir para imágenes grandes).
class BocadoNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final Widget? errorWidget;

  const BocadoNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memCacheWidth,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) =>
          Container(color: AppTheme.primary.withValues(alpha: 0.06)),
      errorWidget: (_, __, ___) =>
          errorWidget ??
          Container(
            color: AppTheme.primary.withValues(alpha: 0.06),
            child: const Icon(Icons.broken_image_outlined,
                color: AppTheme.primary),
          ),
    );
  }
}

/// `ImageProvider` con caché, para usos que requieren un provider en vez de un
/// widget (`CircleAvatar.backgroundImage`, `DecorationImage.image`).
ImageProvider bocadoImageProvider(String url) =>
    CachedNetworkImageProvider(url);

/// Bottom sheet unificado para elegir el origen de una imagen (cámara o galería).
/// Devuelve el [ImageSource] elegido, o null si el usuario lo descarta.
/// Quien lo llama decide qué hacer con la fuente (single o multi-imagen).
Future<ImageSource?> showImageSourceSheet(BuildContext context) {
  final c = BocadoColors.of(context);
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(BocadoRadius.xl)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: BocadoSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.muted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: BocadoSpacing.sm),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: AppTheme.primary),
            title: Text('Cámara', style: TextStyle(color: c.text)),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
            title: Text('Galería', style: TextStyle(color: c.text)),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: BocadoSpacing.md),
        ],
      ),
    ),
  );
}

/// Botón de toggle de tema (sol/luna). Reemplaza el ValueListenableBuilder
/// repetido en cada AppBar/topbar.
class ThemeToggleButton extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  final bool tooltip;

  const ThemeToggleButton({
    super.key,
    required this.themeNotifier,
    this.tooltip = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        final esDark = mode == ThemeMode.dark;
        return IconButton(
          icon: Icon(
            esDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: AppTheme.primary,
          ),
          onPressed: themeNotifier.toggle,
          tooltip: tooltip ? (esDark ? 'Tema claro' : 'Tema oscuro') : null,
        );
      },
    );
  }
}

/// Estado vacío genérico: ícono atenuado + mensaje centrado.
class BocadoEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final double iconSize;

  const BocadoEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.iconSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final muted = BocadoColors.of(context).muted;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: muted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar cuadrado redondeado con foto (URL o bytes) o, en su defecto,
/// la inicial del usuario. Usado en perfil y edición de perfil.
class BocadoAvatar extends StatelessWidget {
  final String? fotoUrl;
  final Uint8List? fotoBytes;
  final String initial;
  final double size;
  final double radius;
  final double? initialFontSize;
  final Color? background;

  const BocadoAvatar({
    super.key,
    this.fotoUrl,
    this.fotoBytes,
    required this.initial,
    this.size = 88,
    this.radius = 20,
    this.initialFontSize,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    Widget contenido;
    if (fotoUrl != null) {
      contenido = BocadoNetworkImage(
        url: fotoUrl!,
        memCacheWidth: (size * 3).round(),
      );
    } else if (fotoBytes != null) {
      contenido = Image.memory(fotoBytes!, fit: BoxFit.cover);
    } else {
      contenido = Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: initialFontSize ?? size * 0.4,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: background ?? AppTheme.primary.withValues(alpha: 0.15),
      ),
      clipBehavior: Clip.antiAlias,
      child: contenido,
    );
  }
}
