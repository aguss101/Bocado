import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/auth_scaffold.dart';

class ResetPasswordScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const ResetPasswordScreen({super.key, required this.themeNotifier});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool get _passwordsMatch =>
      _newPasswordController.text == _confirmPasswordController.text &&
          _newPasswordController.text.isNotEmpty;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_passwordsMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('¡Contraseña restablecida con éxito!'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // Navigate back to login
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;
    final outline = isDark ? AppTheme.outlineDark : AppTheme.outlineLight;

    return AuthScaffold(
      themeNotifier: widget.themeNotifier,
      child: Center(
        child: Column(
          children: [
            AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Title ───────────────────────────────────────
                  Text(
                    'Restablecer contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresá tu nueva clave de acceso para continuar explorando sabores.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: secondary),
                  ),
                  const SizedBox(height: 28),

                  // ── Nueva contraseña ───────────────────────────
                  const AuthFieldLabel('Nueva contraseña'),
                  const SizedBox(height: 8),
                  AuthTextField(
                    controller: _newPasswordController,
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    obscure: _obscureNew,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: secondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Confirmar contraseña ───────────────────────
                  const AuthFieldLabel('Confirmar contraseña'),
                  const SizedBox(height: 8),
                  AuthTextField(
                    controller: _confirmPasswordController,
                    hint: '••••••••',
                    prefixIcon: Icons.verified_user_outlined,
                    obscure: _obscureConfirm,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: secondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),

                  // ── Match indicator ────────────────────────────
                  if (_confirmPasswordController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _passwordsMatch
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          size: 14,
                          color: _passwordsMatch ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _passwordsMatch
                              ? 'Las contraseñas coinciden'
                              : 'Las contraseñas no coinciden',
                          style: TextStyle(
                            fontSize: 11,
                            color: _passwordsMatch ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),

                  // ── Submit ──────────────────────────────────────
                  AuthPrimaryButton(
                    label: 'Restablecer contraseña',
                    onTap: _submit,
                  ),
                  const SizedBox(height: 20),

                  // ── Back ────────────────────────────────────────
                  Divider(color: outline),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chevron_left,
                            size: 16,
                            color: AppTheme.primary,
                          ),
                          const Text(
                            'Volver al inicio de sesión',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Decorative element ─────────────────────────────
            const SizedBox(height: 24),
            Column(
              children: [
                Container(
                  width: 1,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.restaurant_menu,
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}