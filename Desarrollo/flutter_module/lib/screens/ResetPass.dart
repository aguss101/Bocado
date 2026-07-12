import 'package:flutter/material.dart';
import '../theme/App.dart';
import '../theme/Notifier.dart';
import '../widgets/AuthDetails.dart';
import '../widgets/Common.dart';
import '../services/Usuario.dart';
import '../utils/validations.dart';

class ResetPasswordScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final String correo;
  final String codigo;
  const ResetPasswordScreen({
    super.key,
    required this.themeNotifier,
    required this.correo,
    required this.codigo,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  bool get _passwordsMatch =>
      _newPasswordController.text == _confirmPasswordController.text &&
          _newPasswordController.text.isNotEmpty;

  String? get _passwordError {
    if (_newPasswordController.text.isEmpty) return null;
    return Validaciones.contrasena(_newPasswordController.text);
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  Future<void> _submit() async {
    final errPass = Validaciones.contrasena(_newPasswordController.text);
    if (errPass != null) {
      showBocadoSnack(context,errPass, isError: true);
      return;
    }
    if (!_passwordsMatch) {
      showBocadoSnack(context,'Las contraseñas no coinciden', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await UsuarioService.resetearPassword(
        widget.correo,
        widget.codigo,
        _newPasswordController.text,
      );
      if (!mounted) return;
      showBocadoSnack(context,'¡Contraseña restablecida con éxito!');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (mounted) {
        showBocadoSnack(context,'No se pudo restablecer. El código pudo vencer o ya se usó.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BocadoColors.of(context);
    final isDark = c.isDark;
    final secondary = c.muted;
    final outline = c.border;

    return AuthScaffold(
      themeNotifier: widget.themeNotifier,
      child: Center(
        child: Column(
          children: [
            AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Restablecer contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresá tu nueva clave de acceso para continuar explorando sabores.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: secondary),
                  ),
                  const SizedBox(height: 28),

                  const AuthFieldLabel('Nueva contraseña'),
                  const SizedBox(height: 8),
                  AuthTextField(
                    controller: _newPasswordController,
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    obscure: _obscureNew,
                    onChanged: (_) => setState(() {}),
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

                  if (_passwordError != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.cancel_outlined, size: 14, color: c.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _passwordError!,
                            style: TextStyle(fontSize: 11, color: c.error),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  const AuthFieldLabel('Confirmar contraseña'),
                  const SizedBox(height: 8),
                  AuthTextField(
                    controller: _confirmPasswordController,
                    hint: '••••••••',
                    prefixIcon: Icons.verified_user_outlined,
                    obscure: _obscureConfirm,
                    onChanged: (_) => setState(() {}),
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

                  if (_confirmPasswordController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _passwordsMatch
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          size: 14,
                          color: _passwordsMatch ? c.success : c.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _passwordsMatch
                              ? 'Las contraseñas coinciden'
                              : 'Las contraseñas no coinciden',
                          style: TextStyle(
                            fontSize: 11,
                            color: _passwordsMatch ? c.success : c.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),

                  AuthPrimaryButton(
                    label: _saving ? 'Restableciendo...' : 'Restablecer contraseña',
                    onTap: _submit,
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 20),

                  Divider(color: outline),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_left,
                            size: 16,
                            color: c.primary,
                          ),
                          Text(
                            'Volver al inicio de sesión',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: c.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
                        c.primary.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.restaurant_menu,
                  color: c.primary.withValues(alpha: 0.4),
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