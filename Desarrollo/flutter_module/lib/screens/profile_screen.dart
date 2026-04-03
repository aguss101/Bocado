import 'package:flutter/material.dart';
import '../theme/theme_notifier.dart';
import '../theme/app_theme.dart';
import 'shared_drawer.dart'; // ── 1. IMPORTAMOS EL MENÚ ──

class ProfileScreen extends StatelessWidget {
  final int usuarioId; // ── 2. AGREGAMOS EL ID ──
  final String usuarioNombre;
  final ThemeNotifier themeNotifier;

  const ProfileScreen({
    super.key,
    required this.usuarioId, // Lo pedimos como obligatorio
    required this.usuarioNombre,
    required this.themeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1A1108) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2D1D0E) : Colors.grey.shade300;
    final textColor = isDark ? const Color(0xFFFDF7F2) : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0701) : Colors.grey.shade50,

      // ── 3. AGREGAMOS EL CAJÓN LATERAL ──
      endDrawer: SharedDrawer(
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre,
        themeNotifier: themeNotifier,
        rutaActual: 'perfil', // Le avisamos que estamos en el perfil
      ),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primary),
        title: Text('Perfil', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        // ── 4. BOTÓN PARA ABRIR EL MENÚ ──
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.primary),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Foto de perfil grande
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      usuarioNombre.isNotEmpty ? usuarioNombre[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppTheme.primary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Nombre de usuario
            Text(
              usuarioNombre,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text('@${usuarioNombre.toLowerCase().replaceAll(' ', '')}', style: const TextStyle(color: AppTheme.primary)),

            const SizedBox(height: 24),

            // Estadísticas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatColumn('Recetas', '12', textColor),
                Container(height: 40, width: 1, color: borderColor, margin: const EdgeInsets.symmetric(horizontal: 24)),
                _buildStatColumn('Seguidores', '845', textColor),
                Container(height: 40, width: 1, color: borderColor, margin: const EdgeInsets.symmetric(horizontal: 24)),
                _buildStatColumn('Siguiendo', '150', textColor),
              ],
            ),

            const SizedBox(height: 32),

            // Grid de recetas del usuario
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mis creaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 16),
                  // Aquí iría un GridView.builder con las fotos de las recetas del perfil
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: 4, // 4 recetas de ejemplo
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            image: const DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=300&auto=format&fit=crop'),
                              fit: BoxFit.cover,
                            )
                        ),
                      );
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count, Color textColor) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}