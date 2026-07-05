import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/App.dart';
import '../theme/Notifier.dart';
import '../widgets/AuthDetails.dart';
import '../services/Usuario.dart';

class ConfirmEditScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final int idUsuario;
  final String correo;
  final Map<String, dynamic> datos;

  const ConfirmEditScreen({
    super.key,
    required this.themeNotifier,
    required this.idUsuario,
    required this.correo,
    required this.datos,
  });

  @override
  State<ConfirmEditScreen> createState() => _ConfirmEditScreenState();
}

class _ConfirmEditScreenState extends State<ConfirmEditScreen> {
  final _codeController = TextEditingController();
  bool _sending = false;
  bool _saving = false;

  static const _resendCooldown = 600;
  Timer? _resendTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _enviar(isResend: false);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
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

  Future<void> _enviar({required bool isResend}) async {
    setState(() => _sending = true);
    try {
      await UsuarioService.solicitarOtp(widget.correo);
      if (!mounted) return;
      _startCooldown();
      _snack(isResend ? 'Te enviamos un nuevo código.' : 'Te enviamos un código a tu correo.');
    } catch (_) {
      if (mounted) _snack('No se pudo enviar el código. Reintentá.', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmar() async {
    final codigo = _codeController.text.trim();
    if (codigo.length < 6) {
      _snack('Ingresá el código de 6 dígitos.', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await UsuarioService.actualizarPerfilOtp(
        id: widget.idUsuario,
        codigo: codigo,
        datos: widget.datos,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) _snack('Código inválido o vencido. Probá de nuevo.', isError: true);
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
        child: AuthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Confirmá los cambios',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Te enviamos un código a tu correo para confirmar la modificación de tus datos sensibles.',
                style: TextStyle(fontSize: 13, color: secondary),
              ),
              const SizedBox(height: 28),

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

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _secondsLeft > 0
                    ? Text(
                        'Podés reenviar el código en ${_fmt(_secondsLeft)}',
                        style: TextStyle(fontSize: 11, color: secondary),
                      )
                    : GestureDetector(
                        onTap: _sending ? null : () => _enviar(isResend: true),
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
              const SizedBox(height: 28),

              AuthPrimaryButton(
                label: _saving ? 'Confirmando...' : 'Confirmar cambios',
                onTap: _confirmar,
                enabled: !_saving,
              ),
              const SizedBox(height: 20),

              Divider(color: outline),
              const SizedBox(height: 16),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Cancelar',
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
