import 'package:flutter/material.dart';
import '../theme/App.dart';
import '../theme/Notifier.dart';
import 'Common.dart';

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
          _AuthHeader(
            themeNotifier: themeNotifier,
            isDark: isDark,
            outline: outline,
            trailing: headerTrailing,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: child,
            ),
          ),

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
            Text(
              'Bocado',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
                letterSpacing: -0.5,
              ),
            ),
            Row(
              children: [
                if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
                ThemeToggleButton(themeNotifier: themeNotifier, tooltip: true),
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
            '© 2026 Bocado Culinario',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: secondary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}


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
  final ValueChanged<String>? onChanged;

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
    this.onChanged,
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
      onChanged: onChanged,
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
  final bool loading;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (enabled && !loading) ? onTap : null,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
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

class AuthErrorBox extends StatelessWidget {
  final String message;
  const AuthErrorBox(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Center(
          child: Icon(Icons.restaurant_menu, color: AppTheme.primary, size: 40),
        ),
        SizedBox(height: 4),
        Center(
          child: Text(
            'PLATAFORMA GOURMET',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
              letterSpacing: 2,
            ),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }
}

class AuthDropdown extends StatelessWidget {
  final int? value;
  final String hint;
  final IconData icon;
  final List<dynamic> items;
  final ValueChanged<int?> onChanged;

  const AuthDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = BocadoColors.of(context);
    return DropdownButtonFormField<int>(
      isExpanded: true,
      initialValue: value,
      dropdownColor: c.surface,
      style: TextStyle(fontSize: 14, color: c.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.muted, fontSize: 14),
        prefixIcon: Icon(icon, color: c.muted, size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
      items: items.map<DropdownMenuItem<int>>((it) {
        return DropdownMenuItem<int>(value: it['id'], child: Text(it['nombre']));
      }).toList(),
      onChanged: onChanged,
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
    final double scaleX = size.width / 24.0;
    final double scaleY = size.height / 24.0;
    canvas.scale(scaleX, scaleY);

    final Paint paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF4285F4);
    final pathAzul = Path()
      ..moveTo(23.49, 12.27)
      ..cubicTo(23.49, 11.48, 23.42, 10.73, 23.3, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.51)
      ..lineTo(18.44, 14.51)
      ..cubicTo(18.16, 16.02, 17.31, 17.3, 16.03, 18.16)
      ..lineTo(16.03, 21.14)
      ..lineTo(19.93, 21.14)
      ..cubicTo(22.21, 19.04, 23.49, 15.94, 23.49, 12.27);
    canvas.drawPath(pathAzul, paint);

    paint.color = const Color(0xFF34A853);
    final pathVerde = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.24, 24.0, 17.96, 22.92, 19.93, 21.14)
      ..lineTo(16.03, 18.16)
      ..cubicTo(14.95, 18.88, 13.6, 19.32, 12.0, 19.32)
      ..cubicTo(8.87, 19.32, 6.22, 17.21, 5.27, 14.36)
      ..lineTo(1.23, 14.36)
      ..lineTo(1.23, 17.49)
      ..cubicTo(3.21, 21.42, 7.28, 24.0, 12.0, 24.0);
    canvas.drawPath(pathVerde, paint);

    paint.color = const Color(0xFFFBBC05);
    final pathAmarillo = Path()
      ..moveTo(5.27, 14.36)
      ..cubicTo(5.03, 13.64, 4.9, 12.87, 4.9, 12.0)
      ..cubicTo(4.9, 11.13, 5.03, 10.36, 5.27, 9.64)
      ..lineTo(5.27, 6.51)
      ..lineTo(1.23, 6.51)
      ..cubicTo(0.45, 8.16, 0.0, 10.01, 0.0, 12.0)
      ..cubicTo(0.0, 13.99, 0.45, 15.84, 1.23, 17.49)
      ..lineTo(5.27, 14.36);
    canvas.drawPath(pathAmarillo, paint);

    paint.color = const Color(0xFFEA4335);
    final pathRojo = Path()
      ..moveTo(12.0, 4.68)
      ..cubicTo(13.76, 4.68, 15.35, 5.29, 16.59, 6.48)
      ..lineTo(20.02, 3.05)
      ..cubicTo(17.95, 1.12, 15.23, 0.0, 12.0, 0.0)
      ..cubicTo(7.28, 0.0, 3.21, 2.58, 1.23, 6.51)
      ..lineTo(5.27, 9.64)
      ..cubicTo(6.22, 6.79, 8.87, 4.68, 12.0, 4.68);
    canvas.drawPath(pathRojo, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}