import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final MethodChannel _channel = const MethodChannel('com.example.bocado/recetas');

  int _step = 1;

  // Controladores
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _buscarCtrl = TextEditingController();
  final TextEditingController _prepCtrl = TextEditingController();
  final TextEditingController _porcionesCtrl = TextEditingController(text: "1");
  final TextEditingController _pesoCtrl = TextEditingController(text: "0");
  final TextEditingController _tiempoCtrl = TextEditingController(text: "0");
  final TextEditingController _caloriasCtrl = TextEditingController(text: "0");

  String _dificultad = "Principiante";

  List<dynamic> _catalogo = [];
  List<dynamic> _filtrados = [];
  final List<Map<String, dynamic>> _ingredientes = [];

  final Map<int, TextEditingController> _cantidadControllers = {};
  final Map<int, TextEditingController> _precioControllers = {};
  final List<String> _pasos = [];

  @override
  void initState() {
    super.initState();
    _cargarAlimentos();
    _buscarCtrl.addListener(() => _filtrar(_buscarCtrl.text));
  }

  Future<void> _cargarAlimentos() async {
    try {
      final res = await _channel.invokeMethod("getAlimentos");
      if (mounted) {
        setState(() => _catalogo = res ?? []);
      }
    } catch (e) {
      print("ERROR: $e");
    }
  }

  void _filtrar(String texto) {
    final t = texto.toLowerCase().trim();
    if (t.isEmpty) {
      setState(() => _filtrados = []);
      return;
    }
    final resultados = _catalogo.where((item) {
      final nombre = item["nombre"].toString().toLowerCase();
      return nombre.contains(t);
    }).toList();
    setState(() => _filtrados = resultados);
  }

  void _agregar(dynamic alimento) {
    if (_ingredientes.any((e) => e["id"] == alimento["id"])) return;
    setState(() {
      _ingredientes.add({
        "id": alimento["id"],
        "nombre": alimento["nombre"],
        "cantidad": 1,
        "precio": 0.0,
        "medida": "g",
      });
      _buscarCtrl.clear();
      _filtrados.clear();
    });
  }

  void _snack(String msg, [bool error = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: error ? const Color(0xFFB91C1C) : const Color(0xFFD96E11),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgApp = isDark ? const Color(0xFF0D0701) : const Color(0xFFFFFBF5);
    final Color bgPanel = isDark ? const Color(0xFF1A1108) : Colors.white;
    final Color textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color borderColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopNavBar(bgPanel, textMain, borderColor),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStepIndicator(textMain),
                    const SizedBox(height: 30),
                    _buildCurrentStep(bgPanel, textMain, borderColor),
                  ],
                ),
              ),
            ),
            _buildFooter(bgPanel, textMain, borderColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavBar(Color bgPanel, Color textMain, Color borderColor) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: bgPanel, border: Border(bottom: BorderSide(color: borderColor))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFFD96E11), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text("Bocado", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textMain)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor)),
            child: Row(children: [
              Icon(Icons.visibility, size: 14, color: textMain.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text("VISTA PREVIA", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textMain.withOpacity(0.5))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(Color textMain) {
    return Column(
      children: [
        const Text("PASO DE EDICIÓN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFD96E11), letterSpacing: 2)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6, width: _step == i+1 ? 40 : 12,
            decoration: BoxDecoration(color: _step >= i+1 ? const Color(0xFFD96E11) : textMain.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          )),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(Color bgPanel, Color textMain, Color borderColor) {
    switch (_step) {
      case 1: return _step1(bgPanel, textMain, borderColor);
      case 2: return _step2(bgPanel, textMain, borderColor);
      case 3: return _step3(bgPanel, textMain, borderColor);
      case 4: return _step4(bgPanel, textMain, borderColor);
      default: return const SizedBox.shrink();
    }
  }

  Widget _step1(Color bgPanel, Color textMain, Color borderColor) {
    return Column(
      children: [
        _card(bgPanel, borderColor, [
          _label("TÍTULO DE LA RECETA"),
          TextField(controller: _nombreCtrl, style: TextStyle(color: textMain), decoration: _input("Ej: Pasta al dente...")),
          const SizedBox(height: 20),
          _label("DESCRIPCIÓN"),
          TextField(controller: _descCtrl, maxLines: 4, style: TextStyle(color: textMain), decoration: _input("Cuenta la historia...")),
        ]),
        const SizedBox(height: 20),
        _card(bgPanel, borderColor, [
          _label("FOTO PRINCIPAL"),
          Container(
            height: 150, width: double.infinity,
            decoration: BoxDecoration(color: textMain.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.add_a_photo, size: 40, color: Color(0xFFD96E11)),
          )
        ]),
      ],
    );
  }

  Widget _step2(Color bgPanel, Color textMain, Color borderColor) {
    return Column(
      children: [
        _card(bgPanel, borderColor, [
          _label("BUSCAR ALIMENTOS"),
          TextField(controller: _buscarCtrl, style: TextStyle(color: textMain), decoration: _input("Escribí para buscar...")),
          if (_filtrados.isNotEmpty)
            Container(
              height: 150,
              margin: const EdgeInsets.only(top: 10),
              child: ListView.builder(
                itemCount: _filtrados.length,
                itemBuilder: (c, i) => ListTile(
                  title: Text(_filtrados[i]["nombre"], style: TextStyle(color: textMain, fontSize: 14)),
                  trailing: const Icon(Icons.add_circle_outline, color: Color(0xFFD96E11)),
                  onTap: () => _agregar(_filtrados[i]),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 20),
        _label("LISTA DE INGREDIENTES"),
        ..._ingredientes.map((ing) => _ingRow(ing, bgPanel, textMain, borderColor)).toList(),
      ],
    );
  }

  Widget _step3(Color bgPanel, Color textMain, Color borderColor) {
    return Column(
      children: [
        _card(bgPanel, borderColor, [
          _label("NUEVA INSTRUCCIÓN"),
          TextField(controller: _prepCtrl, maxLines: 3, style: TextStyle(color: textMain), decoration: _input("Describe el paso...")),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD96E11)),
            onPressed: () {
              if (_prepCtrl.text.isNotEmpty) {
                setState(() { _pasos.add(_prepCtrl.text); _prepCtrl.clear(); });
              }
            },
            child: const Text("AGREGAR PASO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          )
        ]),
        const SizedBox(height: 20),
        _label("PASOS ACTUALES"),
        ..._pasos.asMap().entries.map((e) => _pasoRow(e.key, e.value, bgPanel, textMain, borderColor)).toList(),
      ],
    );
  }

  Widget _step4(Color bgPanel, Color textMain, Color borderColor) {
    return Column(
      children: [
        _card(bgPanel, borderColor, [
          _label("PORCIONES"),
          TextField(controller: _porcionesCtrl, keyboardType: TextInputType.number, style: TextStyle(color: textMain), decoration: _input("Cant.")),
          const SizedBox(height: 20),
          _label("TIEMPO (MIN)"),
          TextField(controller: _tiempoCtrl, keyboardType: TextInputType.number, style: TextStyle(color: textMain), decoration: _input("Minutos")),
        ]),
        const SizedBox(height: 20),
        _card(bgPanel, borderColor, [
          _label("DIFICULTAD"),
          DropdownButton<String>(
            value: _dificultad, isExpanded: true, dropdownColor: bgPanel,
            items: ["Principiante", "Intermedio", "Experto"].map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: textMain)))).toList(),
            onChanged: (v) => setState(() => _dificultad = v!),
          )
        ]),
      ],
    );
  }

  Widget _card(Color bg, Color border, List<Widget> children) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFD96E11), letterSpacing: 1)));

  InputDecoration _input(String h) => InputDecoration(hintText: h, hintStyle: const TextStyle(color: Colors.grey, fontSize: 14), border: InputBorder.none, filled: true, fillColor: Colors.black.withOpacity(0.05));

  Widget _ingRow(Map<String, dynamic> ing, Color bg, Color text, Color border) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(children: [
        Expanded(child: Text(ing["nombre"], style: TextStyle(color: text, fontWeight: FontWeight.bold))),
        IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => setState(() => _ingredientes.remove(ing))),
      ]),
    );
  }

  Widget _pasoRow(int i, String v, Color bg, Color text, Color border) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(children: [
        CircleAvatar(radius: 12, backgroundColor: const Color(0xFFD96E11), child: Text("${i+1}", style: const TextStyle(color: Colors.white, fontSize: 12))),
        const SizedBox(width: 10),
        Expanded(child: Text(v, style: TextStyle(color: text, fontSize: 13))),
      ]),
    );
  }

  Widget _buildFooter(Color bgPanel, Color textMain, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bgPanel, border: Border(top: BorderSide(color: borderColor))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_step > 1)
            TextButton(
                onPressed: () => setState(() => _step--),
                child: const Text("VOLVER", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD96E11), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
            onPressed: () {
              if (_step < 4) {
                setState(() { _step++; });
              } else {
                _snack("Guardando...");
              }
            },
            child: Text(_step == 4 ? "GUARDAR" : "SIGUIENTE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}