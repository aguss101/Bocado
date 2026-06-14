import 'package:flutter/material.dart';
import 'package:flutter_module/models/usuario_Logged.dart';
import '../services/session_service.dart';
import '../theme/theme_notifier.dart';
import '../theme/app_theme.dart';
import 'feed_screen.dart';
import 'login_screen.dart';
import 'my_recipes_screen.dart';
import 'profile_screen.dart';
import 'recipe_editor_screen.dart';

class SharedDrawer extends StatelessWidget {
  final usuario_Logged user;
  final ThemeNotifier themeNotifier;
  final String rutaActual;

  const SharedDrawer({
    super.key,
    required this.user,
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
                    backgroundImage: NetworkImage(
                        user.fotoUrl ?? 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.usuario, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        Text('ID: ${user.id}', style: TextStyle(fontSize: 12, color: mutedColor)),
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
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FeedScreen(themeNotifier: themeNotifier, user: user)));
                        } else {
                          Navigator.pop(context);
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
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MyRecipesScreen(themeNotifier: themeNotifier, user: user)));
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
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeEditorScreen(themeNotifier: themeNotifier, user: user)));
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
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfileScreen(themeNotifier: themeNotifier, user: user)));
                        } else {
                          Navigator.pop(context);
                        }
                      }
                  ),
                ],
              ),
            ),

            // ── CERRAR SESIÓN ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                tileColor: Colors.red.withValues(alpha: 0.08),
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  await SessionService.clearSession();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => LoginScreen(themeNotifier: themeNotifier)),
                      (_) => false,
                    );
                  }
                },
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