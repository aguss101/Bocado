import 'package:flutter/material.dart';
import '../theme/theme_notifier.dart';
import '../theme/app_theme.dart';
import 'feed_screen.dart';
import 'my_recipes_screen.dart';
import 'profile_screen.dart';
import 'recipe_editor_screen.dart';

class SharedDrawer extends StatelessWidget {
  final int usuarioId;
  final String usuarioNombre;
  final ThemeNotifier themeNotifier;
  final String rutaActual; // 'inicio', 'recetas', 'perfil', etc.

  const SharedDrawer({
    super.key,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.themeNotifier,
    required this.rutaActual,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1A1108) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2D1D0E) : Colors.grey.shade300;
    final textColor = isDark ? const Color(0xFFFDF7F2) : Colors.black87;
    final mutedColor = isDark ? const Color(0xFFA38B75) : Colors.grey.shade600;

    return Drawer(
      backgroundColor: surfaceColor,
      child: SafeArea(
        child: Column(
          children: [
            // ── CABECERA DEL MENÚ ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      usuarioNombre.isNotEmpty ? usuarioNombre[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(usuarioNombre, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        Text('ID: $usuarioId', style: TextStyle(fontSize: 12, color: mutedColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: borderColor),

            // ── LISTA DE OPCIONES ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildMenuItem(
                      context: context,
                      icon: Icons.home_outlined,
                      title: 'Inicio',
                      isActive: rutaActual == 'inicio',
                      onTap: () {
                        if (rutaActual != 'inicio') {
                          // Usamos pushReplacement para no apilar pantallas infinitamente
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FeedScreen(
                              themeNotifier: themeNotifier, usuarioId: usuarioId, usuarioNombre: usuarioNombre
                          )));
                        } else {
                          Navigator.pop(context); // Solo cierra el cajón si ya estoy ahí
                        }
                      }
                  ),
                  _buildMenuItem(
                      context: context,
                      icon: Icons.restaurant_menu,
                      title: 'Mis Recetas',
                      isActive: rutaActual == 'recetas',
                      onTap: () {
                        if (rutaActual != 'recetas') {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MyRecipesScreen(
                              usuarioId: usuarioId, usuarioNombre: usuarioNombre, themeNotifier: themeNotifier,
                          )));
                        } else {
                          Navigator.pop(context);
                        }
                      }
                  ),

                  // Botón Crear Receta
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      leading: const Icon(Icons.add_circle, color: Colors.white),
                      title: const Text('Crear Receta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.pop(context); // Cerramos el menú
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeEditorScreen(
                          themeNotifier: themeNotifier,
                          usuarioId: usuarioId,
                          usuarioNombre: usuarioNombre,
                        )));
                      },
                    ),
                  ),

                  Divider(color: borderColor),

                  _buildMenuItem(
                      context: context,
                      icon: Icons.person_outline,
                      title: 'Perfil',
                      isActive: rutaActual == 'perfil',
                      onTap: () {
                        if (rutaActual != 'perfil') {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfileScreen(
                              usuarioId: usuarioId, usuarioNombre: usuarioNombre, themeNotifier: themeNotifier
                          )));
                        } else {
                          Navigator.pop(context);
                        }
                      }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── WIDGET DE BOTÓN INDIVIDUAL ──
  Widget _buildMenuItem({
    required BuildContext context, required IconData icon, required String title,
    required bool isActive, required VoidCallback onTap
  }) {
    final color = isActive ? AppTheme.primary : Colors.grey.shade500;

    return Container(
      decoration: isActive
          ? BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8))
          : null,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: onTap,
      ),
    );
  }
}