import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_module/models/UsuarioLogged.dart';
import 'package:flutter_module/theme/Notifier.dart';

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
    _esPremium = widget.user.id_Cuenta==2;
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
    return Scaffold(
      appBar: AppBar(title: const Text("Tienda Premium")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildTypeCard("Gratuita", !_esPremium)),
                const SizedBox(width: 10),
                Expanded(child: _buildTypeCard("Premium", _esPremium)),
              ],
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Opciones Premium",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Esta característica será añadida en futuras versiones.")),
                    ),
                    child: const Text("\$5.000 /mes"),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _mostrarDialogoCodigo(),
                    child: const Text("Canjear Código"),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _esPremium ? () => _cambiarEstadoPremium(false) : null,
                    child: const Text("Cancelar suscripción"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text("Beneficios:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
            ),

            ..._beneficios.map((b) => ListTile(
                leading: const Icon(Icons.check, color: Colors.green),
                title: Text(b)
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.amber.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? Colors.amber : Colors.transparent),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (isSelected) const Text("Tu cuenta actual", style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  void _mostrarDialogoCodigo() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ingresar código"),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              _canjearCodigo(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Canjear"),
          ),
        ],
      ),
    );
  }
}