import 'package:flutter/material.dart';
import '../theme/App.dart';
import '../theme/ColorblindNotifier.dart';

String _nombrePerfil(ColorblindProfile perfil) {
  switch (perfil) {
    case ColorblindProfile.protanopia:
      return 'Protanopia';
    case ColorblindProfile.deuteranopia:
      return 'Deuteranopia';
    case ColorblindProfile.tritanopia:
      return 'Tritanopia';
  }
}

String _descripcionPerfil(ColorblindProfile perfil) {
  switch (perfil) {
    case ColorblindProfile.protanopia:
      return 'Dificultad para distinguir rojos';
    case ColorblindProfile.deuteranopia:
      return 'Dificultad para distinguir verdes';
    case ColorblindProfile.tritanopia:
      return 'Dificultad para distinguir azules y amarillos';
  }
}

class ColorblindSettingsScreen extends StatelessWidget {
  const ColorblindSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = ColorblindScope.of(context);

    return ValueListenableBuilder<ColorblindConfig>(
      valueListenable: notifier,
      builder: (context, config, __) {
        final c = BocadoColors.of(context);
        return Scaffold(
          backgroundColor: c.bg,
          appBar: AppBar(
            backgroundColor: c.bg.withValues(alpha: 0.9),
            elevation: 0,
            iconTheme: IconThemeData(color: c.muted),
            title: Text(
              'Modo daltónico',
              style: TextStyle(color: c.text, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(BocadoSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(BocadoSpacing.lg),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(BocadoRadius.lg),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Activar modo daltónico',
                              style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ajusta los colores de toda la app para que sean más fáciles de distinguir.',
                              style: TextStyle(color: c.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: config.enabled,
                        activeColor: c.primary,
                        onChanged: (v) => notifier.setEnabled(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BocadoSpacing.xl),
                Text(
                  'PERFIL',
                  style: TextStyle(
                    color: c.muted,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: BocadoSpacing.sm),
                ...ColorblindProfile.values.map((perfil) {
                  final seleccionado = config.profile == perfil;
                  final habilitado = config.enabled;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: BocadoSpacing.sm),
                    child: Opacity(
                      opacity: habilitado ? 1.0 : 0.4,
                      child: Material(
                        color: seleccionado && habilitado
                            ? c.primary.withValues(alpha: 0.1)
                            : c.surface,
                        borderRadius: BorderRadius.circular(BocadoRadius.md),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(BocadoRadius.md),
                          onTap: habilitado ? () => notifier.setProfile(perfil) : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: BocadoSpacing.lg,
                              vertical: BocadoSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(BocadoRadius.md),
                              border: Border.all(
                                color: seleccionado && habilitado ? c.primary : c.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  seleccionado ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: seleccionado && habilitado ? c.primary : c.muted,
                                ),
                                const SizedBox(width: BocadoSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _nombrePerfil(perfil),
                                        style: TextStyle(
                                          color: c.text,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _descripcionPerfil(perfil),
                                        style: TextStyle(color: c.muted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
