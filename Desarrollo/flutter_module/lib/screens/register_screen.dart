import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/auth_scaffold.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const RegisterScreen({super.key, required this.themeNotifier});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;
    final outline = isDark ? AppTheme.outlineDark : AppTheme.outlineLight;

    return AuthScaffold(
      themeNotifier: widget.themeNotifier,
      headerTrailing: GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(themeNotifier: widget.themeNotifier),
          ),
        ),
        child: RichText(
          text: TextSpan(
            text: '¿Ya tenés cuenta? ',
            style: TextStyle(fontSize: 12, color: secondary),
            children: const [
              TextSpan(
                text: 'Iniciá sesión',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      child: Center(
        child: AuthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Title ─────────────────────────────────────────
              Text(
                'Crea tu cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Uníte a la comunidad de chefs más exclusiva',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: secondary),
              ),
              const SizedBox(height: 28),

              // ── Nombre / Apellido ──────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AuthFieldLabel('Nombre'),
                        const SizedBox(height: 8),
                        AuthTextField(
                          controller: _nombreController,
                          hint: 'Ej. Juan',
                          prefixIcon: Icons.person_outline,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AuthFieldLabel('Apellido'),
                        const SizedBox(height: 8),
                        AuthTextField(
                          controller: _apellidoController,
                          hint: 'Ej. Pérez',
                          prefixIcon: Icons.person_outline,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Email ─────────────────────────────────────────
              const AuthFieldLabel('Correo electrónico'),
              const SizedBox(height: 8),
              AuthTextField(
                controller: _emailController,
                hint: 'tu@email.com',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // ── Usuario ───────────────────────────────────────
              const AuthFieldLabel('Nombre de usuario'),
              const SizedBox(height: 8),
              AuthTextField(
                controller: _usuarioController,
                hint: '@tu_usuario',
                prefixIcon: Icons.alternate_email,
              ),
              const SizedBox(height: 20),

              // ── Password ──────────────────────────────────────
              const AuthFieldLabel('Contraseña'),
              const SizedBox(height: 8),
              AuthTextField(
                controller: _passwordController,
                hint: '••••••••',
                prefixIcon: Icons.lock_outline,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: secondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 20),

              // ── Terms ─────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _acceptTerms,
                      onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                      activeColor: AppTheme.primary,
                      side: BorderSide(color: outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                      child: RichText(
                        text: TextSpan(
                          text: 'Acepto los ',
                          style: TextStyle(fontSize: 12, color: secondary),
                          children: const [
                            TextSpan(
                              text: 'Términos de Servicio',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: ' y la '),
                            TextSpan(
                              text: 'Política de Privacidad',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Submit ────────────────────────────────────────
              AuthPrimaryButton(
                label: 'Registrarse',
                onTap: _acceptTerms ? () {} : () {},
                enabled: _acceptTerms,
              ),
              const SizedBox(height: 20),

              // ── Divider ───────────────────────────────────────
              const AuthDivider(label: 'O REGISTRATE CON'),
              const SizedBox(height: 20),

              // ── Google ────────────────────────────────────────
              GoogleButton(onTap: () {}),
              const SizedBox(height: 20),

              // ── Security badge ────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: outline)),
                ),
                child: Center(
                  child: Text(
                    'Seguridad de nivel profesional con cifrado de extremo a extremo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: secondary,
                      fontWeight: FontWeight.w500,
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