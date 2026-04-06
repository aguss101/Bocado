import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class RecipeEditorScreen extends StatefulWidget {
  final dynamic themeNotifier;
  final int usuarioId;
  final String usuarioNombre;

  const RecipeEditorScreen({
    super.key,
    required this.themeNotifier,
    required this.usuarioId,
    required this.usuarioNombre,
  });

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final MethodChannel _channel = const MethodChannel("bocado_channel");

  int _step = 1;

  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();
  final TextEditingController _prepCtrl = TextEditingController();
  final TextEditingController _porcionesCtrl = TextEditingController(text: "1");
  final TextEditingController _tiempoCtrl = TextEditingController(text: "0");

  List<String> _pasos = [];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _prepCtrl.dispose();
    _porcionesCtrl.dispose();
    _tiempoCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF0D0701) : const Color(0xFFFFFBF5),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _stepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildStep(),
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.restaurant_menu, color: AppTheme.primary),
          const SizedBox(width: 10),
          const Text(
            "Editor de Recetas",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _stepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _step == i + 1 ? 40 : 20,
            height: 6,
            decoration: BoxDecoration(
              color: _step >= i + 1
                  ? AppTheme.primary
                  : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return _step1();
      case 2:
        return _step2();
      case 3:
        return _step3();
      case 4:
        return _step4();
      default:
        return const Text("Error");
    }
  }

  Widget _step1() {
    return Column(
      children: [
        _card([
          const Text("TÍTULO"),
          TextField(controller: _nombreCtrl),
          const SizedBox(height: 20),
          const Text("DESCRIPCIÓN"),
          TextField(controller: _descripcionCtrl, maxLines: 4),
        ]),
        const SizedBox(height: 16),
        _card([
          const Text("FOTO"),
          Container(
            height: 150,
            color: Colors.grey.withOpacity(0.2),
            child: const Center(child: Icon(Icons.add_a_photo)),
          )
        ])
      ],
    );
  }

  Widget _step2() {
    return const Center(child: Text("INGREDIENTES (simplificado)"));
  }

  Widget _step3() {
    return Column(
      children: [
        _card([
          const Text("AGREGAR PASO"),
          TextField(controller: _prepCtrl),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_prepCtrl.text.isNotEmpty) {
                  setState(() {
                    _pasos.add(_prepCtrl.text);
                    _prepCtrl.clear();
                  });
                }
              },
              child: const Text("AGREGAR"),
            ),
          )
        ]),
        const SizedBox(height: 16),
        ..._pasos.map((e) => ListTile(title: Text(e)))
      ],
    );
  }

  Widget _step4() {
    return Column(
      children: [
        _card([
          const Text("PORCIONES"),
          TextField(controller: _porcionesCtrl),
          const SizedBox(height: 20),
          const Text("TIEMPO"),
          TextField(controller: _tiempoCtrl),
        ])
      ],
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_step > 1)
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _step--),
                child: const Text("VOLVER"),
              ),
            ),
          if (_step > 1) const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_step < 4) {
                  setState(() => _step++);
                } else {
                  _snack("Guardar pendiente");
                }
              },
              child: Text(_step == 4 ? "GUARDAR" : "SIGUIENTE"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}