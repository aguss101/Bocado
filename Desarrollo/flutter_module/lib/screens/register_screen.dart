import 'package:flutter/material.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _acceptTerms = false;
  String? _selectedGender;

  static const _primary = Color(0xFFEE7C2B);
  static const _bgDark = Color(0xFF1A120B);
  static const _fieldBg = Color(0xFF2D1F14);

  final _genders = ['Masculino', 'Femenino', 'Otro', 'Prefiero no decir'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildForm(),
                  const SizedBox(height: 24),
                  _buildLoginLink(),
                  const SizedBox(height: 16),
                  Text('© 2024 Bocado App. All rights reserved.', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.2))),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -60,
          left: -60,
          child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: _primary.withValues(alpha: 0.12))),
        ),
        Positioned(
          bottom: -60,
          right: -60,
          child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withValues(alpha: 0.06))),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            const Text('Bocado', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Crear Cuenta', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 6),
        Text('Uníte a la comunidad y empezá tu viaje culinario.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF221810),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildField(hint: 'Juan García', label: 'Nombre Completo', icon: Icons.person_outline)),
              const SizedBox(width: 12),
              Expanded(child: _buildField(hint: 'juancho', label: 'Alias', icon: Icons.badge_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          _buildField(hint: 'juan@ejemplo.com', label: 'Email', icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildField(hint: 'juangarcia88', label: 'Usuario', icon: Icons.alternate_email),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDateField()),
              const SizedBox(width: 12),
              Expanded(child: _buildGenderDropdown()),
            ],
          ),
          const SizedBox(height: 20),
          _buildTermsCheckbox(),
          const SizedBox(height: 20),
          _buildRegisterButton(),
        ],
      ),
    );
  }

  Widget _buildField({required String hint, required String label, required IconData icon, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6))),
        const SizedBox(height: 6),
        TextField(
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.35), size: 18),
            filled: true,
            fillColor: _fieldBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primary.withValues(alpha: 0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primary.withValues(alpha: 0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contraseña', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6))),
        const SizedBox(height: 6),
        TextField(
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
            prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.35), size: 18),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white.withValues(alpha: 0.35), size: 18),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: _fieldBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primary.withValues(alpha: 0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primary.withValues(alpha: 0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fecha de Nac.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6))),
        const SizedBox(height: 6),
        TextField(
          readOnly: true,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'DD/MM/AAAA',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 12),
            prefixIcon: Icon(Icons.calendar_today_outlined, color: Colors.white.withValues(alpha: 0.35), size: 17),
            filled: true,
            fillColor: _fieldBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primary.withValues(alpha: 0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primary.withValues(alpha: 0.2))),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1920),
              lastDate: DateTime.now(),
            );
            if (date != null) {}
          },
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Género', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6))),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          dropdownColor: const Color(0xFF2D1F14),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: Icon(Icons.expand_more, color: Colors.white.withValues(alpha: 0.35)),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.wc_outlined, color: Colors.white.withValues(alpha: 0.35), size: 18),
            filled: true,
            fillColor: _fieldBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primary.withValues(alpha: 0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primary.withValues(alpha: 0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          hint: Text('Seleccionar', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 12)),
          items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (val) => setState(() => _selectedGender = val),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _acceptTerms,
            onChanged: (val) => setState(() => _acceptTerms = val ?? false),
            activeColor: _primary,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'Acepto los ',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
              children: const [
                TextSpan(text: 'Términos de Servicio', style: TextStyle(color: Color(0xFF38BDF8))),
                TextSpan(text: ' y la '),
                TextSpan(text: 'Política de Privacidad', style: TextStyle(color: Color(0xFF38BDF8))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _acceptTerms
            ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()))
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          disabledBackgroundColor: _primary.withValues(alpha: 0.3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: const Text('Registrarse', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('¿Ya tenés cuenta? ', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          child: const Text('Iniciar sesión', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _primary)),
        ),
      ],
    );
  }
}
