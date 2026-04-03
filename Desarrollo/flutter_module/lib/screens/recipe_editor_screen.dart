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

  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _buscarCtrl = TextEditingController();
  final TextEditingController _prepCtrl = TextEditingController();

  final TextEditingController _porcionesCtrl = TextEditingController();
  final TextEditingController _pesoCtrl = TextEditingController();
  final TextEditingController _tiempoCtrl = TextEditingController();

  String _pesoUnidad = "g";
  String _dificultad = "Principiante";

  List<dynamic> _catalogo = [];
  List<dynamic> _filtrados = [];
  List<Map<String, dynamic>> _ingredientes = [];

  final Map<int, TextEditingController> _cantidadControllers = {};
  final Map<int, TextEditingController> _precioControllers = {};
  List<String> _pasos = [];

  @override
  void initState() {
    super.initState();
    _cargarAlimentos();

    _buscarCtrl.addListener(() {
      _filtrar(_buscarCtrl.text);
    });
  }

  Future<void> _cargarAlimentos() async {
    try {
      final res = await _channel.invokeMethod("getAlimentos");

      setState(() {
        _catalogo = res ?? [];
      });

      print("CATALOGO: ${_catalogo.length}");
    } catch (e) {
      print("ERROR: $e");
      _snack("Error cargando alimentos", true);
    }
  }

  void _filtrar(String texto) {
    final t = texto.toLowerCase().trim();

    if (t.isEmpty) {
      setState(() => _filtrados = []);
      return;
    }

    final resultados = _catalogo.where((item) {
      try {
        final nombre = item["nombre"].toString().toLowerCase();
        return nombre.contains(t);
      } catch (_) {
        return false;
      }
    }).toList();

    setState(() {
      _filtrados = resultados;
    });
  }

  void _agregar(dynamic alimento) {
    final id = alimento["id"];

    if (_ingredientes.any((e) => e["id"] == id)) {
      _snack("Ya agregado", true);
      return;
    }

    setState(() {
      _ingredientes.add({
        "id": id,
        "nombre": alimento["nombre"],
        "cantidad": 1,
        "precio": 0,
        "medida": "g",
      });

      _buscarCtrl.clear();
      _filtrados.clear();
    });
  }

  void _snack(String msg, [bool error = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _nav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final n = i + 1;
        return GestureDetector(
          onTap: () => setState(() => _step = n),
          child: Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _step == n ? Colors.orange : Colors.grey[800],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text("$n"),
          ),
        );
      }),
    );
  }

  Widget _step1() {
    return Column(
      children: [
        TextField(
          controller: _nombreCtrl,
          decoration: const InputDecoration(labelText: "Nombre de receta"),
        ),
        const SizedBox(height: 20),
        Container(
          height: 150,
          width: 150,
          color: Colors.grey[800],
          child: const Icon(Icons.image, size: 50),
        ),
      ],
    );
  }

  Widget _step2() {
    return Column(
      children: [
        // Buscador de alimentos
        TextField(
          controller: _buscarCtrl,
          decoration: const InputDecoration(labelText: "Buscar alimento"),
        ),

        // Resultados filtrados
        if (_filtrados.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              itemCount: _filtrados.length,
              itemBuilder: (_, i) {
                final a = _filtrados[i];
                final yaAgregado = _ingredientes.any((e) => e["id"] == a["id"]);
                return ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          a["nombre"],
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      if (yaAgregado)
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    ],
                  ),
                  onTap: yaAgregado ? null : () => _agregar(a),
                );
              },
            ),
          ),

        const SizedBox(height: 10),

        // Lista de ingredientes agregados
        Expanded(
          child: ListView.builder(
            itemCount: _ingredientes.length,
            itemBuilder: (_, i) {
              final ing = _ingredientes[i];

              // Controladores
              final cantidadCtrl = _cantidadControllers.putIfAbsent(
                ing["id"],
                    () => TextEditingController(text: ing["cantidad"].toString()),
              );
              final precioCtrl = _precioControllers.putIfAbsent(
                ing["id"],
                    () => TextEditingController(text: ing["precio"].toString()),
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila: nombre + eliminar
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ing["nombre"],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _ingredientes.removeAt(i)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Fila: cantidad | unidad | precio (alineado al eliminar)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Cantidad
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: cantidadCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 5,
                            decoration: const InputDecoration(
                              labelText: "Cant",
                              counterText: "",
                              isDense: true,
                            ),
                            onChanged: (v) => ing["cantidad"] = int.tryParse(v) ?? 0,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Unidad
                        SizedBox(
                          width: 90,
                          child: DropdownButtonFormField<String>(
                            value: ing["medida"],
                            items: ["g", "kg", "ml", "u"]
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) => setState(() => ing["medida"] = v),
                            decoration: const InputDecoration(labelText: "Unid", isDense: true),
                          ),
                        ),
                        const Spacer(),

                        // Precio (justo debajo del botón eliminar)
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: precioCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            maxLength: 8,
                            decoration: const InputDecoration(
                              labelText: "Precio",
                              counterText: "",
                              prefixText: "\$",
                              isDense: true,
                            ),
                            onChanged: (v) => ing["precio"] = int.tryParse(v) ?? 0,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 16, color: Colors.grey),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _step3() {
    return Column(
      children: [
        // TextField temporal para nuevo paso
        TextField(
          controller: _prepCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: "Nuevo paso",
            hintText: "Escribí un paso de la receta...",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),

        // Botón para agregar paso
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              final texto = _prepCtrl.text.trim();
              if (texto.isNotEmpty) {
                setState(() {
                  _pasos.add(texto);  // _pasos es List<String>
                  _prepCtrl.clear();
                });
              } else {
                _snack("El paso no puede estar vacío", true);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text("Agregar Paso"),
          ),
        ),

        const SizedBox(height: 12),

        // Lista de pasos agregados
        Expanded(
          child: _pasos.isEmpty
              ? const Center(child: Text("No hay pasos agregados"))
              : ListView.builder(
            itemCount: _pasos.length,
            itemBuilder: (_, i) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text("${i + 1}"),
                    radius: 14,
                  ),
                  title: TextField(
                    controller: TextEditingController(text: _pasos[i]),
                    maxLines: null, // permite que el paso se expanda verticalmente
                    style: const TextStyle(fontSize: 12), // fuente más pequeña
                    onChanged: (v) => _pasos[i] = v,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _pasos.removeAt(i)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _step4() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),

          TextField(
            controller: _porcionesCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Porciones"),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pesoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Peso por porción"),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _pesoUnidad,
                items: ["g", "kg", "ml"]
                    .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _pesoUnidad = v!),
              )
            ],
          ),

          const SizedBox(height: 15),

          TextField(
            controller: _tiempoCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Tiempo (min)"),
          ),

          const SizedBox(height: 15),

          DropdownButtonFormField<String>(
            value: _dificultad,
            items: [
              "Principiante",
              "Aficionado",
              "Avanzado",
              "Profesional",
              "Experto"
            ]
                .map((e) =>
                DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _dificultad = v!),
            decoration: const InputDecoration(labelText: "Dificultad"),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _snack("Guardar pendiente");
              },
              child: const Text("Guardar"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    switch (_step) {
      case 1:
        body = _step1();
        break;
      case 2:
        body = _step2();
        break;
      case 3:
        body = _step3();
        break;
      default:
        body = _step4();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Editor de receta")),
      body: Column(
        children: [
          _nav(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}