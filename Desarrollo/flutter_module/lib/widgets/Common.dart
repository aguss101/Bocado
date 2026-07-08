import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/App.dart';
import '../theme/Notifier.dart';
import '../services/Receta.dart';

void showBocadoSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

Future<bool> mostrarDialogoEliminarReceta(
  BuildContext context, {
  required int idReceta,
  required int idUsuario,
}) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        '¿Eliminar receta permanentemente?',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: const Text(
        'Esta acción no se puede deshacer. También se eliminarán los '
        'comentarios, calificaciones y guardados de esta receta.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  if (confirmar != true) return false;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await RecetaService.eliminarReceta(idReceta, idUsuario);
    messenger.showSnackBar(
      const SnackBar(content: Text('Receta eliminada correctamente')),
    );
    return true;
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Error al eliminar la receta. Revisa tu conexión.')),
    );
    return false;
  }
}

Widget bocadoDeleteBadge({required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
    ),
  );
}

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

ImageProvider bocadoImageProvider(String url) =>
    CachedNetworkImageProvider(url);

Future<void> showFullscreenImage(
  BuildContext context, {
  String? url,
  Uint8List? bytes,
}) {
  if ((url == null || url.isEmpty) && bytes == null) return Future.value();
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullscreenImageViewer(url: url, bytes: bytes),
    ),
  );
}

class _FullscreenImageViewer extends StatelessWidget {
  final String? url;
  final Uint8List? bytes;

  const _FullscreenImageViewer({this.url, this.bytes});

  @override
  Widget build(BuildContext context) {
    final Widget imagen = url != null && url!.isNotEmpty
        ? CachedNetworkImage(imageUrl: url!, fit: BoxFit.contain)
        : Image.memory(bytes!, fit: BoxFit.contain);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox.expand(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(child: imagen),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
