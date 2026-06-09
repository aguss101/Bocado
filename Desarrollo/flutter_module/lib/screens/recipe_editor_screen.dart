import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Requerido para MethodChannel
import 'package:flutter_module/models/usuario_Logged.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_upload_service.dart';
import '../theme/theme_notifier.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const _primary = Color(0xFFD96E11);
const _bg = Color(0xFFFFFBF5);
const _surface = Color(0xFFFFFFFF);
const _surfaceDim = Color(0xFFF5F5F5);
const _outline = Color(0xFFE8CCB1);
const _onSurface = Color(0xFF0F172A);
const _onSurfaceVariant = Color(0xFF475569);
const _error = Color(0xFFB91C1C);

// ─── Ingredient model ────────────────────────────────────────────────────────
class _Ingredient {
  final int idAlimento; // ID proveniente de la Base de Datos
  String name;
  String category;
  String quantity;
  String unit;
  double price; // Manejado numéricamente para cálculos precisos

  _Ingredient({
    required this.idAlimento,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.price,
  });
}

// ─── Step model ──────────────────────────────────────────────────────────────
class _RecipeStep {
  String description;
  _RecipeStep({required this.description});
}

// ─── Main screen ─────────────────────────────────────────────────────────────
class RecipeEditorScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final usuario_Logged user;

  const RecipeEditorScreen({
    super.key,
    required this.themeNotifier,
    required this.user
  });

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen>
    with TickerProviderStateMixin {

  // Instanciación del MethodChannel idéntico al de Android (Java)
  static const MethodChannel _channel = MethodChannel('com.example.bocado/recetas');

  int _step = 1;

  // Step 1
  Uint8List? _portadaBytes;
  bool _uploadingPortada = false;
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  // Step 2
  final _ingSearchCtrl = TextEditingController();
  final List<_Ingredient> _ingredients = []; // Lista limpia de inicio dinámico

  List<Map<String, dynamic>> _dbAlimentosMaster = []; // Repositorio de la DB
  List<Map<String, dynamic>> _suggestions = [];      // Resultados filtrados
  bool _cargandoAlimentos = true;

  // Step 3
  final _prepCtrl = TextEditingController();
  final List<_RecipeStep> _pasos = []; // Inicializado vacío para dinámica real

  // Step 4
  final _porcionesCtrl = TextEditingController();
  final _pesoPorcionCtrl = TextEditingController();
  final _tiempoCtrl = TextEditingController();
  final _caloriasCtrl = TextEditingController();
  int _dificultad = 1; // 0 Principiante, 1 Intermedio, 2 Experto
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cargarAlimentosDesdeDB();
    _ingSearchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _ingSearchCtrl.removeListener(_onSearchChanged);
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _ingSearchCtrl.dispose();
    _prepCtrl.dispose();
    _porcionesCtrl.dispose();
    _pesoPorcionCtrl.dispose();
    _tiempoCtrl.dispose();
    _caloriasCtrl.dispose();
    super.dispose();
  }

  // Descarga los alimentos mapeados por el DAO nativo
  Future<void> _cargarAlimentosDesdeDB() async {
    try {
      final List<dynamic>? res = await _channel.invokeMethod('getAlimentos');
      if (res != null) {
        setState(() {
          _dbAlimentosMaster = res.map((e) => Map<String, dynamic>.from(e)).toList();
          _cargandoAlimentos = false;
        });
      }
    } catch (e) {
      setState(() => _cargandoAlimentos = false);
      _snack('Error al sincronizar catálogo de alimentos: $e');
    }
  }

  // Filtrado local predictivo según la escritura en la barra de búsqueda
  void _onSearchChanged() {
    final query = _ingSearchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() {
      _suggestions = _dbAlimentosMaster.where((alimento) {
        final nombre = (alimento['nombre'] ?? '').toString().toLowerCase();
        return nombre.contains(query);
      }).toList();
    });
  }

  // Agrega de manera rápida un alimento nuevo no existente a la base de datos
  Future<void> _crearNuevoAlimentoAlVuelo(String nombreAlimento) async {
    if (nombreAlimento.trim().isEmpty) return;
    try {
      // Llamada directa al handleAddAlimento de tu RecetasChannel
      final dynamic result = await _channel.invokeMethod('addAlimento', {
        'nombre': nombreAlimento.trim(),
        'id_usuario': widget.user.id,
      });

      if (result != null && result['id'] != null) {
        final int nuevoId = result['id'];
        final nuevoElemento = {
          'id': nuevoId,
          'nombre': nombreAlimento.trim(),
          'categoria': 'Personalizado',
          'precio': 0.0
        };

        // Actualizar estados maestro e incluir automáticamente en la lista seleccionada
        setState(() {
          _dbAlimentosMaster.add(nuevoElemento);
          _agregarIngredienteLista(nuevoElemento);
          _ingSearchCtrl.clear();
        });
        _snack('¡"$nombreAlimento" guardado y añadido!');
      }
    } catch (e) {
      _snack('Error al dar de alta el alimento: $e');
    }
  }

  void _agregarIngredienteLista(Map<String, dynamic> item) {
    // Evitar duplicados inmediatos en la misma receta
    if (_ingredients.any((element) => element.idAlimento == item['id'])) {
      _snack('${item['nombre']} ya se encuentra añadido');
      return;
    }

    setState(() {
      _ingredients.add(_Ingredient(
        idAlimento: item['id'] ?? 0,
        name: item['nombre'] ?? 'Desconocido',
        category: item['categoria'] ?? 'General',
        quantity: '100', // Valor por defecto editable
        unit: 'gr',      // Unidad base estándar
        price: (item['precio'] != null) ? double.tryParse(item['precio'].toString()) ?? 0.0 : 0.0,
      ));
    });
  }

  // Calcula la sumatoria matemática del precio total de los ingredientes añadidos
  double _calcularCostoTotal() {
    double total = 0.0;
    for (var ing in _ingredients) {
      final cant = double.tryParse(ing.quantity) ?? 0.0;
      // Suponiendo precio guardado por Kg/Lt de referencia en la base de datos
      total += (cant / 1000) * ing.price;
    }
    return total;
  }

  // Ensamblado final de estructura JSON y guardado en la Base de Datos Remota
  Future<void> _persistirRecetaFinal() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      _snack('Por favor, introduce el título de la receta');
      return;
    }

    setState(() => _isSaving = true);

    // Une los pasos creados en un String separado por saltos de línea para Supabase
    String instruccionesConcatenadas = _pasos.asMap().entries.map((e) {
      return '${e.key + 1}. ${e.value.description}';
    }).join('\n');

    if (instruccionesConcatenadas.isEmpty) {
      instruccionesConcatenadas = _prepCtrl.text.trim();
    }

    // Modelado estructural compatible con el tipo jsonb p_data del store procedure de Postgres
    final Map<String, dynamic> payload = {
      'id_usuario': widget.user.id,
      'nombre': _nombreCtrl.text.trim(),
      'calorias_totales': double.tryParse(_caloriasCtrl.text.trim()) ?? 0.0,
      'porciones': int.tryParse(_porcionesCtrl.text.trim()) ?? 1,
      'instrucciones': instruccionesConcatenadas,
      'precio': _calcularCostoTotal(),
      'ingredientes': _ingredients.map((ing) => {
        'id_alimento': ing.idAlimento,
        'cantidad': double.tryParse(ing.quantity) ?? 0.0,
        'precio': ing.price,
      }).toList(),
    };

    try {
      final String? response = await _channel.invokeMethod<String>('saveReceta', payload);
      _snack('¡Receta creada con éxito en la base de datos!');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Error al impactar en Supabase: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _seleccionarPortada(ImageSource source) async {
    setState(() => _uploadingPortada = true);
    try {
      final bytes = await ImageUploadService.pickAndCompressReceta(source);
      if (bytes != null && mounted) setState(() => _portadaBytes = bytes);
    } catch (e) {
      if (mounted) _snack('Error al cargar imagen: $e');
    } finally {
      if (mounted) setState(() => _uploadingPortada = false);
    }
  }

  Future<void> _mostrarPickerPortada() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: _primary),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _primary),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source != null) await _seleccionarPortada(source);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildStep(),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _surface.withOpacity(0.92),
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Bocado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _onSurface, letterSpacing: -0.5),
          ),
          const Spacer(),
          _pillButton(icon: Icons.visibility_outlined, label: 'VISTA PREVIA', onTap: () {}),
        ],
      ),
    );
  }

  Widget _pillButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: _onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: _onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            'EDITOR DE RECETAS',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _primary.withOpacity(0.8), letterSpacing: 3),
          ),
          const SizedBox(height: 6),
          Text(
            'Paso $_step de 4',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _onSurface, letterSpacing: -0.5),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final active = _step == i + 1;
              final done = _step > i + 1;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 36 : 20,
                height: 6,
                decoration: BoxDecoration(
                  color: (active || done) ? _primary : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active ? [BoxShadow(color: _primary.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))] : [],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      case 3: return _buildStep3();
      case 4: return _buildStep4();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('TÍTULO DE LA RECETA'),
              const SizedBox(height: 8),
              _textField(controller: _nombreCtrl, hint: 'Ej: Risotto de Azafrán y Setas Silvestres', fontSize: 16, fontWeight: FontWeight.w700),
              const SizedBox(height: 20),
              _fieldLabel('BREVE DESCRIPCIÓN'),
              const SizedBox(height: 8),
              _textField(controller: _descripcionCtrl, hint: 'Cuenta la historia detrás de este plato, su origen o qué lo hace especial...', maxLines: 5),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Galería de fotos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _onSurface)),
                  Text('MÍNIMO 1 FOTO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _primary.withOpacity(0.6), letterSpacing: 1.5)),
                ],
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _uploadingPortada ? null : _mostrarPickerPortada,
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: _surfaceDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _outline.withOpacity(0.6), width: 1.5, strokeAlign: BorderSide.strokeAlignInside),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _portadaBytes != null
                      ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(_portadaBytes!, fit: BoxFit.cover),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                          child: const Text('CAMBIAR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  )
                      : _uploadingPortada
                      ? const Center(child: CircularProgressIndicator(color: _primary))
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: _primary.withOpacity(0.12), shape: BoxShape.circle),
                        child: const Icon(Icons.add_photo_alternate_outlined, color: _primary, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text('SUBIR FOTO PRINCIPAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _onSurfaceVariant.withOpacity(0.8), letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                    height: 72,
                    decoration: BoxDecoration(color: _surfaceDim, borderRadius: BorderRadius.circular(10), border: Border.all(color: _outline.withOpacity(0.4))),
                    child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFFCBD5E1), size: 22),
                  ),
                )),
              ),
              const SizedBox(height: 12),
              Center(child: Text('JPG, PNG • Máx 10 MB • Recomendamos luz natural', style: TextStyle(fontSize: 10, color: _onSurfaceVariant.withOpacity(0.6)), textAlign: TextAlign.center)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('AÑADIR INGREDIENTE'),
              const SizedBox(height: 10),
              _searchField(controller: _ingSearchCtrl, hint: 'Buscar ingrediente en la base de datos...'),
              const SizedBox(height: 14),

              if (_cargandoAlimentos)
                const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: _primary)))
              else ...[
                Text(
                  _suggestions.isEmpty && _ingSearchCtrl.text.isNotEmpty ? 'OPCIONES DISPONIBLES' : 'SUGERENCIAS ENCONTRADAS',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _onSurfaceVariant.withOpacity(0.5), letterSpacing: 2),
                ),
                const SizedBox(height: 8),

                ..._suggestions.map((s) => _suggestionRow(s)),

                if (_suggestions.isEmpty && _ingSearchCtrl.text.trim().isNotEmpty)
                  _buildAddAlimentoAlVueloRow(_ingSearchCtrl.text.trim()),
              ]
            ],
          ),
        ),
        const SizedBox(height: 16),

        // CAMBIO CLAVE: Quitamos la altura rígida innecesaria del contenedor inferior
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Forzamos a que use solo el espacio de sus hijos reales
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.06),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('LISTA DE INGREDIENTES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _primary, letterSpacing: 2)),
                    Text('${_ingredients.length} ITEMS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _onSurfaceVariant.withOpacity(0.6), letterSpacing: 1.5)),
                  ],
                ),
              ),

              if (_ingredients.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No hay ingredientes seleccionados todavía.', style: TextStyle(fontSize: 13, color: _onSurfaceVariant, fontStyle: FontStyle.italic)),
                )
              else
              // Usamos un operador spread (...) en lugar de un ListView o columna rígida para que use el scroll general de la pantalla
                ..._ingredients.asMap().entries.map((e) => _ingredientRow(e.value, e.key)),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _surfaceDim,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('COSTO ESTIMADO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _onSurfaceVariant.withOpacity(0.6), letterSpacing: 1.5)),
                        const SizedBox(height: 2),
                        Text('Calculado automáticamente', style: TextStyle(fontSize: 10, color: _onSurfaceVariant.withOpacity(0.5))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('TOTAL ESTIMADO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _primary, letterSpacing: 1.5)),
                        Text(
                          '\$${_calcularCostoTotal().toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _onSurface, letterSpacing: -1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddAlimentoAlVueloRow(String textoIngresado) {
    return InkWell(
      onTap: () => _crearNuevoAlimentoAlVuelo(textoIngresado),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline, color: _primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No encontrado. ¿Deseas dar de alta e incorporar "$textoIngresado"?',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionRow(Map<String, dynamic> s) {
    final String nombreAlimento = s['nombre'] ?? 'Sin Nombre';
    final String categoriaAlimento = s['categoria'] ?? 'Ingrediente';
    final double precioUnitario = (s['precio'] != null) ? double.tryParse(s['precio'].toString()) ?? 0.0 : 0.0;

    return GestureDetector(
      onTap: () {
        _agregarIngredienteLista(s);
        _ingSearchCtrl.clear();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.restaurant_menu, color: _primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombreAlimento, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _onSurface)),
                  Text('$categoriaAlimento • \$${precioUnitario.toStringAsFixed(2)}/Ref',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _onSurfaceVariant.withOpacity(0.6), letterSpacing: 0.5)),
                ],
              ),
            ),
            Icon(Icons.add, color: Colors.black.withOpacity(0.2), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _ingredientRow(_Ingredient ing, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          // 1. Nombre adaptable
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ing.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  ing.category,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _onSurfaceVariant.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // 2. Cantidad (Ahora es un botón táctil seguro, libre de franjas negras)
          _miniInputBox(
            label: 'CANT.',
            initialValue: ing.quantity,
            onChanged: (val) {
              setState(() {
                ing.quantity = val;
              });
            },
          ),
          const SizedBox(width: 4),
          _miniStaticBox(label: 'UNID.', value: ing.unit),
          const SizedBox(width: 8),

          // 3. Precio
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('PRECIO U.', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _onSurfaceVariant.withOpacity(0.5))),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '\$${ing.price.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _onSurface),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // 4. Eliminar
          GestureDetector(
            onTap: () => setState(() => _ingredients.removeAt(index)),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(Icons.delete_outline, color: _onSurfaceVariant.withOpacity(0.4), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInputBox({required String label, required String initialValue, required ValueChanged<String> onChanged}) {
    return GestureDetector(
      onTap: () {
        // Abrimos un diálogo nativo de Flutter para editar el número de forma segura
        final ctrl = TextEditingController(text: initialValue);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Editar Cantidad ($label)'),
            content: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Ingresa el valor numérico'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (ctrl.text.trim().isNotEmpty) {
                    onChanged(ctrl.text.trim());
                  }
                  Navigator.pop(context);
                },
                child: const Text('ACEPTAR'),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        decoration: BoxDecoration(
          color: _surfaceDim,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _outline.withOpacity(0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: _primary)),
            const SizedBox(height: 1),
            // Al ser un texto plano común, es matemáticamente imposible que Flutter dibuje la barra negra de input colapsado
            Center(
              child: Text(
                initialValue,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStaticBox({required String label, required String value}) {
    return Container(
      width: 38, // Reducido para evitar desbordes
      padding: const EdgeInsets.only(top: 4, bottom: 5, left: 4, right: 4),
      decoration: BoxDecoration(
        color: _surfaceDim,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Centrado para que luzca prolijo
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: _primary, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit_note, color: _primary, size: 20),
                      SizedBox(width: 8),
                      Text('NUEVA INSTRUCCIÓN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _onSurface, letterSpacing: 1)),
                    ],
                  ),
                  Text('AÑADIR DETALLES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _onSurfaceVariant.withOpacity(0.4), letterSpacing: 1.2)),
                ],
              ),
              const SizedBox(height: 14),
              _textField(controller: _prepCtrl, hint: 'Describe la técnica, temperatura y tiempos específicos para este paso...', maxLines: 4),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    if (_prepCtrl.text.trim().isNotEmpty) {
                      setState(() {
                        _pasos.add(_RecipeStep(description: _prepCtrl.text.trim()));
                        _prepCtrl.clear();
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('AGREGAR PASO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PASOS ACTUALES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _onSurfaceVariant.withOpacity(0.5), letterSpacing: 2)),
            const Text('REORGANIZAR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _primary, letterSpacing: 1.5)),
          ],
        ),
        const SizedBox(height: 10),
        if (_pasos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Text('No hay instrucciones creadas. Podés tipear arriba y añadir pasos.', style: TextStyle(fontSize: 13, color: _onSurfaceVariant, fontStyle: FontStyle.italic)),
          )
        else
          ..._pasos.asMap().entries.map((e) => _stepCard(e.key, e.value)),
        const SizedBox(height: 16),
        _card(
          color: _surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AYUDA RÁPIDA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _onSurfaceVariant.withOpacity(0.4), letterSpacing: 2)),
              const SizedBox(height: 14),
              _tipRow('Describe acciones concretas con verbos en infinitivo para mayor claridad.'),
              _tipRow('Indica tiempos aproximados de reposo o cocción en cada etapa.'),
              _tipRow('Menciona la textura o color ideal para que el cocinero sepa cuándo avanzar.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepCard(int index, _RecipeStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _outline.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: _primary.withOpacity(0.2))),
            child: Center(child: Text('${index + 1}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _primary))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(step.description, style: TextStyle(fontSize: 13, height: 1.55, color: _onSurfaceVariant.withOpacity(0.85), fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              GestureDetector(onTap: () {}, child: Icon(Icons.edit_outlined, size: 18, color: _onSurfaceVariant.withOpacity(0.35))),
              const SizedBox(height: 8),
              GestureDetector(onTap: () => setState(() => _pasos.removeAt(index)), child: const Icon(Icons.delete_outline, size: 18, color: _error)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tipRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: _primary, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, height: 1.5, color: _onSurfaceVariant.withOpacity(0.75), fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    const dificultades = [
      {'label': 'Principiante', 'icon': Icons.egg_alt_outlined},
      {'label': 'Intermedio', 'icon': Icons.restaurant_outlined},
      {'label': 'Experto', 'icon': Icons.local_fire_department_outlined},
    ];
    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNumberGrid(),
              const SizedBox(height: 20),
              _fieldLabel('DIFICULTAD'),
              const SizedBox(height: 10),
              Row(
                children: List.generate(3, (i) {
                  final selected = _dificultad == i;
                  final info = dificultades[i];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _dificultad = i),
                      child: Container(
                        margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? _primary : _surfaceDim,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? _primary : Colors.black.withOpacity(0.04)),
                        ),
                        child: Column(
                          children: [
                            Icon(info['icon'] as IconData, color: selected ? Colors.white : _onSurfaceVariant, size: 20),
                            const SizedBox(height: 4),
                            Text(info['label'] as String, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? Colors.white : _onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberGrid() {
    return Row(
      children: [
        Expanded(child: _numericItem(controller: _porcionesCtrl, label: 'PORCIONES', suffix: 'pers.')),
        const SizedBox(width: 12),
        Expanded(child: _numericItem(controller: _caloriasCtrl, label: 'CALORÍAS', suffix: 'kcal')),
      ],
    );
  }

  Widget _numericItem({required TextEditingController controller, required String label, required String suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 8),
        _textField(controller: controller, hint: '0', keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _surface, border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05)))),
      child: Row(
        children: [
          if (_step > 1)
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => setState(() => _step--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: _outline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ATRÁS', style: TextStyle(color: _primary, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1)),
              ),
            ),
          if (_step > 1) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                if (_step < 4) {
                  setState(() => _step++);
                } else {
                  await _persistirRecetaFinal();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                _step == 4 ? 'GUARDAR Y PUBLICAR' : 'CONTINUAR',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child, Color color = _surface, EdgeInsetsGeometry padding = const EdgeInsets.all(20)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _onSurfaceVariant.withOpacity(0.6), letterSpacing: 1.5),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: _onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _onSurfaceVariant.withOpacity(0.3), fontWeight: FontWeight.w400),
        filled: true,
        fillColor: _surfaceDim,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withOpacity(0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
      ),
    );
  }

  Widget _searchField({required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _onSurfaceVariant.withOpacity(0.35), fontWeight: FontWeight.w400),
        prefixIcon: Icon(Icons.search, color: _primary.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: _surfaceDim,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withOpacity(0.06))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
      ),
    );
  }
}