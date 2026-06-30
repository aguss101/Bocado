import 'package:flutter/material.dart';
import 'package:flutter_module/models/UsuarioLogged.dart';
import '../services/Session.dart';
import '../services/Update.dart';
import '../theme/App.dart';
import '../theme/Notifier.dart';
import '../widgets/Common.dart';
import 'Feed.dart';
import 'LogIn.dart';
import 'MyRecipes.dart';
import 'Profil.dart';
import 'EditRecipe.dart';
import 'PremiumStore.dart';


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
    final c = BocadoColors.of(context);

    return Drawer(
      backgroundColor: c.surface,
      child: SafeArea(
        child: Column(
          children: [
            // ── CABECERA DEL MENÚ ──
            Padding(
              padding: const EdgeInsets.all(BocadoSpacing.xl),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                    backgroundImage: bocadoImageProvider(
                        user.fotoUrl ?? 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.usuario, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c.text)),
                        Text('ID: ${user.id}', style: TextStyle(fontSize: 12, color: c.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: c.border),

            // ── LISTA DE OPCIONES ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: BocadoSpacing.md),
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
                    margin: const EdgeInsets.symmetric(vertical: BocadoSpacing.sm, horizontal: BocadoSpacing.sm),
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(BocadoRadius.sm)),
                    child: ListTile(
                      leading: const Icon(Icons.add_circle, color: Colors.white),
                      title: const Text('Crear Receta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.pop(context); // Cerramos el menú
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeEditorScreen(themeNotifier: themeNotifier, user: user)));
                      },
                    ),
                  ),
                  _buildMenuItem(
                      context: context,
                      icon: Icons.workspace_premium, // Icono de corona o premium
                      title: 'Premium',
                      isActive: rutaActual == 'premium',
                      onTap: () {
                        if (rutaActual != 'premium') {
                          Navigator.pop(context); // Cerramos el drawer primero
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PremiumStoreScreen(themeNotifier: themeNotifier, user: user))
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      }
                  ),
                  Divider(color: c.border),

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


            // ── ACTUALIZAR (solo si hay versión nueva) ──
            if (UpdateService.cached?.disponible == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  BocadoSpacing.lg,
                  BocadoSpacing.sm,
                  BocadoSpacing.lg,
                  0,
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(BocadoRadius.sm),
                  ),
                  tileColor: AppTheme.primary.withValues(alpha: 0.12),
                  leading: const Icon(Icons.system_update, color: AppTheme.primary),
                  title: const Text(
                    'Actualizar app',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    UpdateService.abrirDescarga();
                  },
                ),
              ),

            // ── CERRAR SESIÓN ──
            Padding(
              padding: const EdgeInsets.all(BocadoSpacing.lg),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BocadoRadius.sm)),
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
    final c = BocadoColors.of(context);
    final color = isActive ? AppTheme.primary : c.muted;

    return Container(
      decoration: isActive
          ? BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(BocadoRadius.sm))
          : null,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BocadoRadius.sm)),
        onTap: onTap,
      ),
    );
  }
}