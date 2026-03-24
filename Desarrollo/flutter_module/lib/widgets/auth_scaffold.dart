import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';

/// Scaffold base para todas las pantallas de autenticación.
/// Incluye header con logo "Bocado", botón de toggle de tema,
/// y footer con links legales.
class AuthScaffold extends StatelessWidget {
  final Widget child;
  final ThemeNotifier themeNotifier;
  final Widget? headerTrailing;

  const AuthScaffold({
    super.key,
    required this.child,
    required this.themeNotifier,
    this.headerTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;
    final outline = isDark ? AppTheme.outlineDark : AppTheme.outlineLight;

    return Scaffold(
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          _AuthHeader(
            themeNotifier: themeNotifier,
            isDark: isDark,
            outline: outline,
            trailing: headerTrailing,
          ),

          // ── Content ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: child,
            ),
          ),

          // ── Footer ──────────────────────────────────────────────
          _AuthFooter(secondary: secondary, outline: outline, isDark: isDark),
        ],
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  final bool isDark;
  final Color outline;
  final Widget? trailing;

  const _AuthHeader({
    required this.themeNotifier,
    required this.isDark,
    required this.outline,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: outline.withValues(alpha: 0.4))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo
            Text(
              'Bocado',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
                letterSpacing: -0.5,
              ),
            ),
            // Actions
            Row(
              children: [
                if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
                // Theme toggle
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
                    tooltip: mode == ThemeMode.dark ? 'Tema claro' : 'Tema oscuro',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthFooter extends StatelessWidget {
  final Color secondary;
  final Color outline;
  final bool isDark;

  const _AuthFooter({
    required this.secondary,
    required this.outline,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: outline.withValues(alpha: 0.4))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 8,
        children: [
          Text(
            '© 2024 Bocado Culinary',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: secondary,
              letterSpacing: 1,
            ),
          ),
          _FooterLink('Privacidad', secondary),
          _FooterLink('Términos', secondary),
          _FooterLink('Ayuda', secondary),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final Color color;
  const _FooterLink(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ── Shared form widgets ────────────────────────────────────────────────────────

class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final outline = isDark ? AppTheme.outlineDark : AppTheme.outlineLight;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: child,
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  final String text;
  const AuthFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight,
        letterSpacing: 1.5,
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final int? maxLength;
  final TextStyle? inputStyle;

  const AuthTextField({
    super.key,
    this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.maxLength,
    this.inputStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? AppTheme.secondaryDark.withValues(alpha: 0.7)
        : AppTheme.secondaryLight.withValues(alpha: 0.7);

    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: inputStyle ??
          TextStyle(
            color: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
            fontSize: 14,
          ),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        prefixIcon: Icon(prefixIcon, color: iconColor, size: 20),
        suffixIcon: suffix,
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  final String label;
  const AuthDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppTheme.outlineDark : AppTheme.outlineLight;
    final textColor = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;

    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: color)),
      ],
    );
  }
}

class GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const GoogleButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppTheme.outlineDark : AppTheme.outlineLight;
    final bg = isDark ? AppTheme.surfaceContainerDark : AppTheme.surfaceContainerLight;
    final textColor = isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google logo SVG simplified as colored text
            _GoogleLogo(),
            const SizedBox(width: 10),
            Text(
              'Continuar con Google',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paths = [
      (const Color(0xFF4285F4), 'M 20 10.2 C 20 9.5 19.9 8.8 19.8 8.2 H 10 V 12 H 15.6 C 15.3 13.4 14.6 14.5 13.5 15.3 V 17.7 H 16.8 C 18.8 15.9 20 13.3 20 10.2 Z'),
      (const Color(0xFF34A853), 'M 10 20 C 12.7 20 14.9 19.1 16.8 17.7 L 13.5 15.3 C 12.6 15.9 11.4 16.3 10 16.3 C 7.4 16.3 5.1 14.5 4.3 12.1 H 0.9 V 14.5 C 2.8 18.3 6.2 20 10 20 Z'),
      (const Color(0xFFFBBC05), 'M 4.3 12.1 C 4.1 11.5 4 10.8 4 10.1 C 4 9.4 4.1 8.7 4.3 8.1 V 5.7 H 0.9 C 0.3 7 0 8.5 0 10.1 C 0 11.7 0.3 13.2 0.9 14.5 L 4.3 12.1 Z'),
      (const Color(0xFFEA4335), 'M 10 3.9 C 11.5 3.9 12.8 4.4 13.8 5.4 L 16.9 2.3 C 14.9 0.4 12.7 0 10 0 C 6.2 0 2.8 2.4 0.9 5.7 L 4.3 8.1 C 5.1 5.7 7.4 3.9 10 3.9 Z'),
    ];

    for (final (color, _) in paths) {
      final paint = Paint()..color = color;
      // Simple colored circle as Google logo approximation
    }

    // Draw a simple 'G' colored circle
    final paint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, paint);
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}