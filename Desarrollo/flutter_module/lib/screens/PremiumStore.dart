import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_module/models/UsuarioLogged.dart';
import 'package:flutter_module/theme/Notifier.dart';
import '../theme/App.dart';
import '../widgets/Common.dart';

class PremiumStoreScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final usuario_Logged user;

  const PremiumStoreScreen({super.key, required this.themeNotifier, required this.user});

  @override
  State<PremiumStoreScreen> createState() => _PremiumStoreScreenState();
}

class _PremiumStoreScreenState extends State<PremiumStoreScreen> {
  static const platform = MethodChannel('com.example.bocado/account');

  bool _esPremium = false;
  final List<String> _codigosValidos = ["PREMIUM2026", "BIENVENIDO"];
  final List<String> _beneficios = [
    "Experiencia sin anuncios",
    "Acceso a recetas exclusivas",
    "Soporte prioritario",
    "Estadísticas nutricionales avanzadas"
  ];

  @override
  void initState() {
    super.initState();
    _esPremium = widget.user.id_Cuenta == 2;
  }

  Future<void> _cambiarEstadoPremium(bool nuevoEstado) async {
    final int nuevoIdCuenta = _esPremium ? 1 : 2;
    try {
      final bool? exito = await platform.invokeMethod('actualizarEstadoPremium', {
        'id_usuario': widget.user.id,
        'id_cuenta': nuevoIdCuenta,
      });

      if (exito == true) {
        setState(() => _esPremium = nuevoEstado);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(nuevoEstado ? "¡Ahora eres Premium!" : "Suscripción cancelada.")),
          );
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al actualizar la cuenta: ${e.message}")),
        );
      }
    }
  }

  void _canjearCodigo(String codigo) {
    if (_codigosValidos.contains(codigo.toUpperCase())) {
      _cambiarEstadoPremium(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Código inválido.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BocadoColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: IconThemeData(color: c.muted),
        title: Text(
          'Tienda Premium',
          style: TextStyle(color: c.text, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          ThemeToggleButton(themeNotifier: widget.themeNotifier),
          const SizedBox(width: BocadoSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BocadoSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── PLAN ACTUAL ──
            Row(
              children: [
                Expanded(child: _buildTypeCard(context, "Gratuita", !_esPremium)),
                const SizedBox(width: BocadoSpacing.md),
                Expanded(child: _buildTypeCard(context, "Premium", _esPremium)),
              ],
            ),
            const SizedBox(height: BocadoSpacing.xl),

            // ── OPCIONES ──
            Container(
              padding: const EdgeInsets.all(BocadoSpacing.lg),
              decoration: BoxDecoration(
                color: c.surfaceContainer,
                borderRadius: BorderRadius.circular(BocadoRadius.lg),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Opciones Premium',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.text, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: BocadoSpacing.lg),
                  ElevatedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Esta característica será añadida en futuras versiones.")),
                    ),
                    child: const Text("\$5.000 /mes"),
                  ),
                  const SizedBox(height: BocadoSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _mostrarDialogoCodigo,
                    icon: const Icon(Icons.redeem, size: 18),
                    label: const Text("Canjear Código"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BocadoRadius.md)),
                    ),
                  ),
                  if (_esPremium) ...[
                    const SizedBox(height: BocadoSpacing.sm),
                    TextButton(
                      onPressed: () => _cambiarEstadoPremium(false),
                      child: const Text(
                        "Cancelar suscripción",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: BocadoSpacing.xl),

            // ── BENEFICIOS ──
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Beneficios:',
                style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: BocadoSpacing.sm),
            ..._beneficios.map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: BocadoSpacing.xs),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                      const SizedBox(width: BocadoSpacing.md),
                      Expanded(
                        child: Text(b, style: TextStyle(color: c.text, fontSize: 14)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(BuildContext context, String title, bool isSelected) {
    final c = BocadoColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: BocadoSpacing.lg, horizontal: BocadoSpacing.md),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withValues(alpha: 0.12) : c.surfaceContainer,
        borderRadius: BorderRadius.circular(BocadoRadius.md),
        border: Border.all(color: isSelected ? AppTheme.primary : c.border),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? AppTheme.primary : c.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(height: BocadoSpacing.xs),
            Text('Tu cuenta actual', style: TextStyle(fontSize: 10, color: c.muted)),
          ],
        ],
      ),
    );
  }

  void _mostrarDialogoCodigo() {
    final c = BocadoColors.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BocadoRadius.lg)),
        title: Text('Ingresar código', style: TextStyle(color: c.text, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: c.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              _canjearCodigo(controller.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: BocadoSpacing.lg),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BocadoRadius.sm)),
            ),
            child: const Text('Canjear'),
          ),
        ],
      ),
    );
  }
}
