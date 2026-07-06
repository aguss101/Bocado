import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/Usuario.dart';
import '../services/Session.dart';
import '../theme/App.dart';
import '../theme/Notifier.dart';
import '../widgets/AuthDetails.dart';
import 'Register.dart';
import 'ForgotPass.dart';
import 'Feed.dart';
import 'OnboardingGoogle.dart';
import '../utils/validations.dart';

class LoginScreen extends StatefulWidget {
final ThemeNotifier themeNotifier;
const LoginScreen({super.key, required this.themeNotifier});

@override
State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
bool _obscurePassword = true;
bool _rememberMe = false;
bool _isLoading = false;
String? _errorMessage;

Future<void> _login() async {
final usuario = _emailController.text.trim();
final contrasena = _passwordController.text;

final error = Validaciones.requerido(usuario, 'Ingresá tu correo o usuario.')
?? Validaciones.requerido(contrasena, 'Ingresá tu contraseña.');
if (error != null) {
setState(() => _errorMessage = error);
return;
}

setState(() {
_isLoading = true;
_errorMessage = null;
});

try {
  final user = await UsuarioService.login(usuario, contrasena);

  if (_rememberMe) await SessionService.saveSession(user);

  if (mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => FeedScreen(
          themeNotifier: widget.themeNotifier,
          user: user,
        ),
      ),
      (route) => false,
    );
  }

} on PlatformException catch (e) {
  setState(() {
    switch (e.code) {
      case 'CRED_INVALIDAS':
        _errorMessage = 'Usuario o contraseña incorrectos.';
        break;
      case 'NETWORK_ERROR':
        _errorMessage = 'Sin conexión con el servidor. Revisá tu internet.';
        break;
      case 'NEGOCIO':
        _errorMessage = e.message ?? 'Revisá los datos ingresados.';
        break;
      case 'ERROR_API':
        _errorMessage = e.message ?? 'El servidor rechazó la solicitud. Intentá de nuevo.';
        break;
      default:
        _errorMessage = e.message ?? 'No se pudo iniciar sesión (${e.code}).';
    }
  });
} catch (e) {
setState(() {
_errorMessage = 'Error procesando la respuesta.';
});
} finally {
if (mounted) setState(() => _isLoading = false);
}
}

Future<void> _loginConGoogle() async {
if (_isLoading) return;
setState(() {
_isLoading = true;
_errorMessage = null;
});
try {
final outcome = await UsuarioService.signInWithGoogle();
if (outcome.cancelado) return;

if (outcome.existente != null) {
final user = outcome.existente!;
if (_rememberMe) await SessionService.saveSession(user);
if (mounted) {
Navigator.pushAndRemoveUntil(
context,
MaterialPageRoute(
builder: (_) => FeedScreen(
themeNotifier: widget.themeNotifier,
user: user,
),
),
(route) => false,
);
}
} else {
if (mounted) {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) => CompleteGoogleProfileScreen(
themeNotifier: widget.themeNotifier,
perfil: outcome.nuevo!,
),
),
);
}
}
} on PlatformException catch (e) {
setState(() {
switch (e.code) {
case 'NETWORK_ERROR':
case 'network_error':
_errorMessage = 'Sin conexión. No se pudo contactar a Google.';
break;
case 'sign_in_failed':
_errorMessage = 'No se pudo iniciar sesión con Google. Verificá la configuración de la cuenta.';
break;
case 'NEGOCIO':
_errorMessage = e.message ?? 'Google no devolvió los datos necesarios.';
break;
default:
_errorMessage = e.message ?? 'No se pudo continuar con Google (${e.code}).';
}
});
} catch (e) {
setState(() => _errorMessage = 'No se pudo iniciar sesión con Google.');
} finally {
if (mounted) setState(() => _isLoading = false);
}
}

@override
void dispose() {
_emailController.dispose();
_passwordController.dispose();
super.dispose();
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
const AuthBrandHeader(),

Text(
'Bienvenido de nuevo',
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.w800,
color: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
),
),
const SizedBox(height: 6),
Text(
'Ingresá tus credenciales para acceder.',
style: TextStyle(fontSize: 13, color: secondary),
),
const SizedBox(height: 28),

const AuthFieldLabel('Correo electrónico o usuario'),
const SizedBox(height: 8),
AuthTextField(
controller: _emailController,
hint: 'Chefsito@gmail.com',
prefixIcon: Icons.person_outline,
keyboardType: TextInputType.emailAddress,
),
const SizedBox(height: 20),

Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const AuthFieldLabel('Contraseña'),
GestureDetector(
onTap: () => Navigator.push(
context,
MaterialPageRoute(
builder: (_) => ForgotPasswordScreen(
themeNotifier: widget.themeNotifier,
),
),
),
child: const Text(
'¿Olvidaste tu contraseña?',
style: TextStyle(
fontSize: 11,
fontWeight: FontWeight.w700,
color: AppTheme.primary,
),
),
),
],
),
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
const SizedBox(height: 16),

Row(
children: [
SizedBox(
width: 20,
height: 20,
child: Checkbox(
value: _rememberMe,
onChanged: (v) => setState(() => _rememberMe = v ?? false),
activeColor: AppTheme.primary,
side: BorderSide(color: outline),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(4)),
),
),
const SizedBox(width: 10),
Text(
'Recordar sesión en este equipo',
style: TextStyle(fontSize: 13, color: secondary),
),
],
),
const SizedBox(height: 20),

if (_errorMessage != null) ...[
AuthErrorBox(_errorMessage!),
const SizedBox(height: 16),
],

AuthPrimaryButton(
label: 'INICIAR SESIÓN',
onTap: _login,
loading: _isLoading,
),
const SizedBox(height: 20),

const AuthDivider(label: 'O'),
const SizedBox(height: 20),

GoogleButton(onTap: _loginConGoogle),

const SizedBox(height: 28),

Divider(color: outline),
const SizedBox(height: 16),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(
'¿No tenés una cuenta? ',
style: TextStyle(fontSize: 13, color: secondary),
),
GestureDetector(
onTap: () => Navigator.push(
context,
MaterialPageRoute(
builder: (_) => RegisterScreen(
themeNotifier: widget.themeNotifier,
),
),
),
child: const Text(
'Registrate gratis',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w800,
color: AppTheme.primary,
),
),
),
],
),
const SizedBox(height: 16),

Center(
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(Icons.shield_outlined, size: 12, color: secondary),
const SizedBox(width: 4),
Text(
'BOCADO',
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w700,
color: secondary,
letterSpacing: 1,
),
),
],
),
),
],
),
),
),
);
}
}