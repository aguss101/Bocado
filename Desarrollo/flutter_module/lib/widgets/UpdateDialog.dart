import 'package:flutter/material.dart';
import '../theme/App.dart';
import '../services/Update.dart';

Future<void> mostrarAvisoActualizacion(
  BuildContext context,
  String versionName,
) {
  final c = BocadoColors.of(context);

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BocadoRadius.lg),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(BocadoSpacing.sm),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(BocadoRadius.sm),
            ),
            child: Icon(Icons.system_update, color: c.primary),
          ),
          const SizedBox(width: BocadoSpacing.md),
          Expanded(
            child: Text(
              'Nueva versión disponible',
              style: TextStyle(
                color: c.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        versionName.isNotEmpty
            ? 'Hay una actualización de Bocado (v$versionName). Actualizá para tener las últimas mejoras.'
            : 'Hay una actualización de Bocado disponible. Actualizá para tener las últimas mejoras.',
        style: TextStyle(color: c.muted, fontSize: 14, height: 1.5),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        BocadoSpacing.lg,
        0,
        BocadoSpacing.lg,
        BocadoSpacing.lg,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('Ahora no', style: TextStyle(color: c.muted)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(ctx).pop();
            UpdateService.abrirDescarga();
          },
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Actualizar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: BocadoSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BocadoRadius.sm),
            ),
          ),
        ),
      ],
    ),
  );
}
