import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/App.dart';
import '../theme/Notifier.dart';
import '../widgets/AuthDetails.dart';
import '../services/Usuario.dart';
import 'ResetPass.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const ForgotPasswordScreen({super.key, required this.themeNotifier});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _sending = false;
  bool _verifying = false;

  // Reenvío: tras enviar el código hay que esperar 10 min (lo que dura el OTP)
  // antes de poder pedir uno nuevo. Mientras tanto mostramos una cuenta regresiva.
  static const _resendCooldown = 600; // segundos = 10 minutos
  Timer? _resendTimer;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _startCooldown() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  /// Pide (o reenvía) el código. Reenviar genera uno NUEVO e invalida el anterior
  /// (lo hace la RPC create_otp en la BD), y reinicia la cuenta regresiva.
  Future<void> _request({required bool isResend}) async {
    final correo = _emailController.text.trim();
    if (correo.isEmpty) {
      _snack('Ingresá tu correo', isError: true);
      return;
    }
    setState(() => _sending = true);
    try {
      await UsuarioService.solicitarOtp(correo);
      if (!mounted) return;
      setState(() => _codeSent = true);
      _startCooldown();
      _snack(isResend
          ? 'Te enviamos un nuevo código.'
          : 'Si el correo existe, te enviamos un código.');
    } catch (_) {
      if (mounted) _snack('No se pudo enviar el código. Reintentá.', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendCode() => _request(isResend: false);
  Future<void> _resendCode() => _request(isResend: true);

  Future<void> _verifyCode() async {
    final correo = _emailController.text.trim();
    final codigo = _codeController.text.trim();
    if (correo.isEmpty || codigo.length < 6) {
      _snack('Completá el correo y el código de 6 dígitos.', isError: true);
      return;
    }
    setState(() => _verifying = true);
    try {
      final ok = await UsuarioService.verificarOtp(correo, codigo);
      if (!mounted) return;
      if (ok) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              themeNotifier: widget.themeNotifier,
              correo: correo,
              codigo: codigo,
            ),
          ),
        );
      } else {
        _snack('Código inválido o vencido.', isError: true);
      }
    } catch (_) {
      if (mounted) _snack('No se pudo verificar el código.', isError: true);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BocadoColors.of(context);
    final isDark = c.isDark;
    final secondary = c.muted;
    final outline = c.border;
    // Habilitado solo si no estamos enviando y no hay cooldown activo.
    final canRequest = !_sending && _secondsLeft == 0;

    return AuthScaffold(
      themeNotifier: widget.themeNotifier,
      child: Center(
        child: AuthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Title ─────────────────────────────────────────
              Text(
                'Recuperar acceso',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Te enviaremos un código para restablecer tu contraseña.',
                style: TextStyle(fontSize: 13, color: secondary),
              ),
              const SizedBox(height: 28),

              // ── Email ─────────────────────────────────────────
              const AuthFieldLabel('Correo electrónico'),
              const SizedBox(height: 8),
              AuthTextField(
                controller: _emailController,
                hint: 'tu@email.com',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),

              // ── Send code button ──────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: canRequest ? _sendCode : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ENVIAR CÓDIGO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: canRequest ? AppTheme.primary : secondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: canRequest ? AppTheme.primary : secondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Verification code ─────────────────────────────
              const AuthFieldLabel('Código de verificación'),
              const SizedBox(height: 8),
              AuthTextField(
                controller: _codeController,
                hint: '000000',
                prefixIcon: Icons.verified_user_outlined,
                maxLength: 6,
                keyboardType: TextInputType.number,
                inputStyle: TextStyle(
                  color: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
                  fontSize: 18,
                  letterSpacing: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),

              // ── Resend hint + cuenta regresiva / reenviar ─────
              if (_codeSent) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 12, color: secondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Revisá tu casilla de correo. Puede tardar unos segundos.',
                        style: TextStyle(fontSize: 11, color: secondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _secondsLeft > 0
                      ? Text(
                          'Podés reenviar el código en ${_fmt(_secondsLeft)}',
                          style: TextStyle(fontSize: 11, color: secondary),
                        )
                      : GestureDetector(
                          onTap: _sending ? null : _resendCode,
                          child: const Text(
                            'Reenviar código',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                ),
              ],
              const SizedBox(height: 28),

              // ── Submit ────────────────────────────────────────
              AuthPrimaryButton(
                label: _verifying ? 'Verificando...' : 'Verificar código',
                onTap: _verifyCode,
                enabled: !_verifying,
              ),
              const SizedBox(height: 20),

              // ── Back to login ─────────────────────────────────
              Divider(color: outline),
              const SizedBox(height: 16),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Volver al inicio de sesión',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}