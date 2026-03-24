import 'package:flutter/material.dart';
import '../theme/theme_notifier.dart';
import '../theme/app_theme.dart';

/// Pantalla principal post-login.
/// Recibe los datos básicos del usuario autenticado.
class FeedScreen extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  final int usuarioId;
  final String usuarioNombre;

  const FeedScreen({
    super.key,
    required this.themeNotifier,
    required this.usuarioId,
    required this.usuarioNombre,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant_menu,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Bocado',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          // Toggle de tema
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (_, mode, __) => IconButton(
              onPressed: themeNotifier.toggle,
              icon: Icon(
                mode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: AppTheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
              child: Text(
                usuarioNombre.isNotEmpty
                    ? usuarioNombre[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppTheme.primary, size: 64),
            const SizedBox(height: 16),
            Text(
              '¡Hola, $usuarioNombre!',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Login exitoso. ID: $usuarioId',
              style: TextStyle(fontSize: 14, color: secondary),
            ),
            const SizedBox(height: 32),
            Text(
              'El FeedScreen completo se integra\naquí con el diseño del repositorio.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: secondary),
            ),
          ],
        ),
      ),
    );
  }
}