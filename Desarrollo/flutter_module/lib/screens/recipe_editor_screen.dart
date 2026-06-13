import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
const bool _isDebug = true;

class _Ingredient {
  int idAlimento;
  final String name;
  final String category;
  String quantity;
  final String unit;
  final double priceBase;
  final int idMedida;
  final int? idUsuario;

  _Ingredient({
    required this.idAlimento,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.priceBase,
    required this.idMedida,
    this.idUsuario,
  });

  double get subtotal {
    final qty = double.tryParse(quantity) ?? 0.0;
    if (idMedida == 1 || idMedida == 2) {
      return (priceBase / 100.0) * qty;
    }
    return priceBase * qty;
  }
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

  static const MethodChannel _channel = MethodChannel('com.example.bocado/recetas');
  int _step = 1;

  // Step 1
  Uint8List? _portadaBytes;
  bool _uploadingPortada = false;
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();


  // Step 2
  final _ingSearchCtrl = TextEditingController();
  final List<_Ingredient> _ingredients = [];
  List<Map<String, dynamic>> _dbAlimentosMaster = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _cargandoAlimentos = true;
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;

  // Step 3
  final _prepCtrl = TextEditingController();
  final List<_RecipeStep> _pasos = [];

  // Step 4
  final _porcionesCtrl = TextEditingController();
  final _pesoPorcionCtrl = TextEditingController();
  final _tiempoCtrl = TextEditingController();
  final _caloriasCtrl = TextEditingController();
  int _dificultad = 2;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _dificultadData = [
    {'label': 'Principiante', 'icon': Icons.child_care, 'id': 1},
    {'label': 'Aficionado',   'icon': Icons.kitchen, 'id': 2},
    {'label': 'Intermedio',   'icon': Icons.fitness_center, 'id': 3},
    {'label': 'Profesional',  'icon': Icons.work_outline, 'id': 4},
    {'label': 'Experto',      'icon': Icons.local_fire_department, 'id': 5},
  ];


  @override
  void initState() {
    super.initState();
    _cargarAlimentosDesdeDB();
    _ingSearchCtrl.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        // Pequeño delay para asegurar que el teclado abrió
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              150, // Ajusta este valor según la altura de tu header
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
            _searchFocusNode.addListener(() {
              setState(() => _isSearching = _searchFocusNode.hasFocus);
            });
          }
        });
      }
    });
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

  Future<void> _crearNuevoAlimentoAlVuelo(String nombreAlimento) async {
    if (nombreAlimento.trim().isEmpty) return;
    try {
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
    if (_ingredients.any((element) => element.idAlimento == item['id'])) {
      _snack('${item['nombre']} ya se encuentra añadido');
      return;
    }

    setState(() {
      _ingredients.add(_Ingredient(
        idAlimento: item['id'] ?? 0,
        name: item['nombre'] ?? 'Desconocido',
        category: item['categoria'] ?? 'General',
        quantity: '100',
        unit: 'gr',
        priceBase: (item['precio'] != null) ? double.tryParse(item['precio'].toString()) ?? 0.0 : 0.0,
        idMedida: 1,
      ));
    });
  }

  double _calcularCostoTotal() {
    return _ingredients.fold<double>(0.0, (sum, item) => sum + item.subtotal);
  }

  Future<void> _persistirRecetaFinal() async {
    setState(() => _isSaving = true);

    try {
      // 1 y 2: Procesar ingredientes nuevos
      // Recorremos la lista de ingredientes que el usuario cargó
      for (var ing in _ingredients) {
        if (ing.idAlimento <= 0) { // Asumimos que <= 0 significa "nuevo"
          // Llamamos al MethodChannel para crear el alimento
          final Map<String, dynamic> response = await const MethodChannel('com.example.bocado/recetas')
              .invokeMethod('addAlimento', {
            'nombre': ing.name,
            'id_usuario': widget.user.id,
          });

          // 3: Actualizamos el ID local con el ID real que nos devolvió la BD
          ing.idAlimento = response['id'];
        }
      }

      // 4: Ahora que todos los ingredientes tienen ID real, guardamos la receta
      final Map<String, dynamic> recetaData = {
        'id_usuario': widget.user.id,
        'nombre': _nombreCtrl.text,
        'calorias_totales': double.tryParse(_caloriasCtrl.text) ?? 0,
        'porciones': int.tryParse(_porcionesCtrl.text) ?? 1,
        'porciones_peso': double.tryParse(_pesoPorcionCtrl.text) ?? 0,
        'id_dificultad': _dificultadData[_dificultad]['id'],
        'instrucciones': _pasos.map((s) => s.description).join('\n'),
        'precio': _calcularCostoTotal(),
        'ingredientes': _ingredients.map((ing) => {
          'id_alimento': ing.idAlimento,
          'nombre': ing.name,
          'cantidad': double.tryParse(ing.quantity) ?? 0,
          'precio': ing.priceBase,
        }).toList(),
      };

      await const MethodChannel('com.example.bocado/recetas')
          .invokeMethod('saveReceta', recetaData);

      _snack('Receta guardada con éxito');
      Navigator.pop(context);

    } catch (e) {
      _snack('Error al guardar: $e');
    } finally {
      setState(() => _isSaving = false);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fondoPantalla = isDark ? const Color(0xFF0F172A) : _bg;
    final fondoTarjetas = isDark ? const Color(0xFF1E293B) : _surface;
    return Scaffold(
      backgroundColor: fondoPantalla,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    cardColor: fondoTarjetas,
                  ),
                  child: _buildStep(),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.92) : _surface.withOpacity(0.92),
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
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
          Text(
            'Bocado',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : _onSurface,
                letterSpacing: -0.5
            ),
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

// ══════════════════════════════════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════════════════════════════════
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'EDITOR DE RECETAS',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: _primary, letterSpacing: 2),
          ),
          Text(
            'Paso $_step de 4',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _onSurface, height: 1.0),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final active = _step == i + 1;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 28 : 16,
                height: 4,
                decoration: BoxDecoration(
                  color: active ? _primary : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
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

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1 – Información Básica y Portada
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep1() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('TÍTULO DE LA RECETA'),
              const SizedBox(height: 8),
              _textField(
                controller: _nombreCtrl,
                hint: 'Ej: Pastel de Papa Tradicional',
              ),
              const SizedBox(height: 16),
              _fieldLabel('BREVE DESCRIPCIÓN'),
              const SizedBox(height: 8),
              _textField(
                controller: _descripcionCtrl,
                hint: 'Cuéntanos un poco sobre este plato, su origen o secretos...',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      'Galería de fotos',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : _onSurface
                      )
                  ),
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
                    color: isDark ? const Color(0xFF0F172A) : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark ? Colors.white10 : _outline.withOpacity(0.6),
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignInside
                    ),
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
                      Text(
                          'SUBIR FOTO PRINCIPAL',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white60 : _onSurfaceVariant.withOpacity(0.8),
                              letterSpacing: 1.2
                          )
                      ),
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
                    decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? Colors.white10 : _outline.withOpacity(0.4))
                    ),
                    child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFFCBD5E1), size: 22),
                  ),
                )),
              ),
              const SizedBox(height: 12),
              Center(
                  child: Text(
                      'JPG, PNG • Máx 10 MB \n • Recomendamos luz natural',
                      style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : _onSurfaceVariant.withOpacity(0.6)
                      ),
                      textAlign: TextAlign.center
                  )
              ),
            ],
          ),
        ),
      ],
    );
  }

// ══════════════════════════════════════════════════════════════════════════
// STEP 2 – Ingredientes (Versión Limpia y Estática)
// ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep2() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('AÑADIR INGREDIENTE'),
              const SizedBox(height: 10),
              _searchField(controller: _ingSearchCtrl, hint: 'Buscar ingrediente...'),

              if (_ingSearchCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('SUGERENCIAS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : _onSurfaceVariant.withOpacity(0.5), letterSpacing: 2)),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _customIngredientRow(_ingSearchCtrl.text.trim()),
                        const Divider(height: 8, thickness: 0.5),
                        ..._suggestions.map((s) => _suggestionRow(s)).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Lista de ingredientes
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.06),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('LISTA DE INGREDIENTES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _primary, letterSpacing: 2)),
                    Text('${_ingredients.length} ITEMS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white60 : _onSurfaceVariant.withOpacity(0.6), letterSpacing: 1.5)),
                  ],
                ),
              ),
              ..._ingredients.asMap().entries.map((e) => _ingredientRow(e.value, e.key)),

              // Footer Costo Estimado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL RECETA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : _onSurfaceVariant.withOpacity(0.7))),
                    Text('\$${_calcularCostoTotal().toStringAsFixed(2)}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isDark ? Colors.white : _onSurface, letterSpacing: -0.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _suggestionRow(Map<String, dynamic> s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idDinamico = (s['id_alimento'] ?? s['id'] ?? -1);
    return GestureDetector(
      onTap: () {
        double precioNum = 0.50;
        if (s['sub'] != null) {
          final String subString = s['sub'].toString();
          if (subString.contains('•')) {
            final partePrecio = subString.split('•').last.replaceAll(RegExp(r'[^\d.]'), '').trim();
            precioNum = double.tryParse(partePrecio) ?? 0.50;
          } else {
            precioNum = double.tryParse(subString.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.50;
          }
        } else if (s['precio'] != null) {
          precioNum = double.tryParse(s['precio'].toString()) ?? 0.50;
        }

        final idDinamico = s['id_alimento'] ?? s['id'] ?? 0;
        final String nombreOriginal = s['name']?.toString() ?? s['nombre']?.toString() ?? 'Ingrediente';
        final String nombreFormateado = nombreOriginal.isNotEmpty
            ? nombreOriginal[0].toUpperCase() + nombreOriginal.substring(1)
            : nombreOriginal;

        if (_ingredients.any((ing) => ing.name.toLowerCase() == nombreFormateado.toLowerCase())) {
          _ingSearchCtrl.clear();
          _suggestions.clear();
          FocusScope.of(context).unfocus();
          _snack('⚠️ El ingrediente "$nombreFormateado" ya está en la lista.');
          return;
        }

        setState(() {
          _ingredients.add(
            _Ingredient(
                idAlimento: idDinamico,
                name: nombreFormateado,
                category: s['categoria'] ?? 'Añadido',
                quantity: '100',
                unit: s['unidad'] ?? 'gr',
                priceBase: precioNum,
                idMedida: 1
            ),
          );
          _ingSearchCtrl.clear();
          _suggestions.clear();
        });
        FocusScope.of(context).unfocus();
        _snack('Añadido: $nombreFormateado');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant_menu, color: _primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s['name']?.toString() ?? s['nombre']?.toString() ?? '',
                    style: TextStyle(
                        fontSize: 11, // Era 13, ahora 12
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : _onSurface
                    ),
                  ),
                  Text(
                    s['sub']?.toString() ?? s['categoria']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 7, // Era 9, ahora 8
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white54 : _onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.add, color: _primary.withOpacity(0.8), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _ingredientRow(_Ingredient ing, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : _onSurface;
    final subtextColor = isDark ? Colors.white54 : _onSurfaceVariant.withOpacity(0.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          // Fila 1 y 2 combinadas: Nombre, Subtotal y Eliminar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ing.name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Text(
                    '\$${ing.subtotal.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: textColor),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _ingredients.removeAt(index)),
                    child: Icon(Icons.delete_outline, color: isDark ? Colors.white38 : _error.withOpacity(0.6), size: 18),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Fila 3: Cantidad, Unidad, Precio Base y Configuración
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Input de cantidad
              Row(
                children: [
                  SizedBox(
                    width: 50, height: 26,
                    child: TextFormField(
                      initialValue: ing.quantity,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                      onFieldSubmitted: (v) {
                        if (v.isEmpty || v == '0') {
                          _showResetQuantityDialog(ing, index);
                        } else {
                          setState(() => ing.quantity = v);
                        }
                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(ing.unit, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subtextColor)),
                ],
              ),

              // Precio base y botón de configuración
              Row(
                children: [
                  Text(
                    ing.idMedida == 3
                        ? '(\$${ing.priceBase.toStringAsFixed(2)} x unid)'
                        : '(\$${ing.priceBase.toStringAsFixed(2)} x 100${ing.unit})',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: subtextColor),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showIngredientDialog(ing: ing),
                    child: Icon(Icons.settings, color: _primary, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

// 4. Fila para crear nuevo personalizado (Simplificada)

  void _showIngredientDialog({_Ingredient? ing, String? newName}) {
    final isEditing = ing != null;
    // Definición de controladores DENTRO del método
    final TextEditingController _cantCtrl = TextEditingController(text: isEditing ? ing.quantity : '100');
    final TextEditingController _precioCtrl = TextEditingController(text: isEditing ? ((double.tryParse(ing.quantity) ?? 1) * (ing.priceBase / (ing.idMedida < 3 ? 100 : 1))).toStringAsFixed(2) : '');
    int _medida = isEditing ? ing.idMedida : 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Editar: ${ing.name}' : 'Configurar: $newName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: _medida,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Peso (Base 100gr)')),
                  DropdownMenuItem(value: 2, child: Text('Volumen (Base 100ml)')),
                  DropdownMenuItem(value: 3, child: Text('Unidad (Base 1)')),
                ],
                onChanged: (v) => setDialogState(() => _medida = v!),
              ),
              TextField(controller: _cantCtrl, decoration: const InputDecoration(labelText: 'Cantidad Comprada'), keyboardType: TextInputType.number),
              TextField(controller: _precioCtrl, decoration: const InputDecoration(labelText: 'Precio Total Pagado \$'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                // Ahora sí, _precioCtrl es accesible desde aquí porque está en el scope del padre
                double cantComprada = double.tryParse(_cantCtrl.text) ?? 0;
                double precioTotal = double.tryParse(_precioCtrl.text) ?? 0;

                if (cantComprada <= 0) return;

                double nuevoPriceBase = (precioTotal / cantComprada);
                if (_medida == 1 || _medida == 2) nuevoPriceBase *= 100;

                setState(() {
                  if (isEditing) {
                    _ingredients[_ingredients.indexOf(ing!)] = _Ingredient(
                        idAlimento: ing.idAlimento,
                        name: ing.name,
                        category: ing.category,
                        quantity: ing.quantity,
                        unit: _medida == 1 ? 'gr' : (_medida == 2 ? 'ml' : 'unid'),
                        priceBase: nuevoPriceBase, idMedida: _medida, idUsuario: ing.idUsuario
                    );
                  } else {
                    _ingredients.add(_Ingredient(
                        idAlimento: DateTime.now().millisecondsSinceEpoch,
                        name: newName!,
                        category: 'Personalizado',
                        quantity: '100',
                        unit: _medida == 1 ? 'gr' : (_medida == 2 ? 'ml' : 'unid'),
                        priceBase: nuevoPriceBase, idMedida: _medida, idUsuario: widget.user.id
                    ));
                    _ingSearchCtrl.clear();
                  }
                });

                Navigator.pop(context);
                // Desenfoque global para cerrar teclado
                FocusManager.instance.primaryFocus?.unfocus();
                _snack('Configuración guardada');
              },
              child: const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customIngredientRow(String textEntered) {
    return GestureDetector(
      onTap: () => _showAdvancedIngredientDialog(textEntered),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _primary.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.blur_on, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '💡 Crear "$textEntered"',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Añadir como ingrediente personalizado',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _onSurfaceVariant.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: _primary, size: 14),
          ],
        ),
      ),
    );
  }

  void _showAdvancedIngredientDialog(String name) {
    final _cantCompraCtrl = TextEditingController();
    final _precioTotalCtrl = TextEditingController();
    int _medidaSeleccionada = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Configurar: $name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: _medidaSeleccionada,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Peso (Base 100gr)')),
                  DropdownMenuItem(value: 2, child: Text('Volumen (Base 100ml)')),
                  DropdownMenuItem(value: 3, child: Text('Unidad (Base 1)')),
                ],
                onChanged: (v) => setDialogState(() => _medidaSeleccionada = v!),
              ),
              TextField(controller: _cantCompraCtrl, decoration: const InputDecoration(labelText: 'Cantidad comprada'), keyboardType: TextInputType.number),
              TextField(controller: _precioTotalCtrl, decoration: const InputDecoration(labelText: 'Precio pagado \$'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                double cant = double.tryParse(_cantCompraCtrl.text) ?? 0;
                double total = double.tryParse(_precioTotalCtrl.text) ?? 0;
                if (cant <= 0) return;

                double precioBaseCalculado = (total / cant);
                if (_medidaSeleccionada == 1 || _medidaSeleccionada == 2) {
                  precioBaseCalculado *= 100;
                }

                setState(() {
                  _ingredients.add(_Ingredient(
                    idAlimento: -1,
                    name: name,
                    category: 'Personalizado',
                    quantity: '100',
                    unit: _medidaSeleccionada == 1 ? 'gr' : (_medidaSeleccionada == 2 ? 'ml' : 'unid'),
                    priceBase: precioBaseCalculado,
                    idMedida: _medidaSeleccionada,
                    idUsuario: widget.user.id,
                  ));
                  _ingSearchCtrl.clear();
                  FocusScope.of(context).unfocus();
                });
                Navigator.pop(context);
              },
              child: const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditIngredientDialog(_Ingredient ing, int index) {
    // Inicializamos controladores con los valores actuales del ingrediente
    final _cantCtrl = TextEditingController(text: ing.quantity);
    final _precioBaseCtrl = TextEditingController(text: ing.priceBase.toStringAsFixed(2));
    int _medidaTemp = ing.idMedida;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Editar: ${ing.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: _medidaTemp,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Peso (Base 100gr)')),
                  DropdownMenuItem(value: 2, child: Text('Volumen (Base 100ml)')),
                  DropdownMenuItem(value: 3, child: Text('Unidad (Base 1)')),
                ],
                onChanged: (v) => setDialogState(() => _medidaTemp = v!),
              ),
              TextField(
                  controller: _cantCtrl,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true)
              ),
              TextField(
                  controller: _precioBaseCtrl,
                  decoration: const InputDecoration(labelText: 'Precio Base'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true)
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                final nuevaCant = _cantCtrl.text.trim();
                final nuevoPrecio = double.tryParse(_precioBaseCtrl.text) ?? 0.0;

                setState(() {
                  // Actualizamos el objeto en la lista
                  _ingredients[index] = _Ingredient(
                    idAlimento: ing.idAlimento,
                    name: ing.name,
                    category: ing.category,
                    quantity: nuevaCant,
                    unit: _medidaTemp == 1 ? 'gr' : (_medidaTemp == 2 ? 'ml' : 'unid'),
                    priceBase: nuevoPrecio,
                    idMedida: _medidaTemp,
                    idUsuario: ing.idUsuario, // Mantenemos el ID del usuario
                  );
                });

                Navigator.pop(context);
                _snack('Ingrediente actualizado');
              },
              child: const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetQuantityDialog(_Ingredient ing, int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Cantidad inválida', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '¿Deseas reiniciar la cantidad de "${ing.name}" a 100 ${ing.unit} o prefieres eliminar el ingrediente de la lista?',
          style: const TextStyle(fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _ingredients.removeAt(index);
              });
              Navigator.pop(context);
              _snack('🗑️ Ingrediente eliminado');
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    ing.quantity = "1";
                  });
                  Navigator.pop(context);
                },
                child: const Text('NO', style: TextStyle(color: _onSurfaceVariant, fontSize: 12)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  setState(() {
                    ing.quantity = "100";
                  });
                  Navigator.pop(context);
                  _snack('🔄 Cantidad restablecida a 100');
                },
                child: const Text('SÍ, REINICIAR', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInputBox({required String label, required String value, required ValueChanged<String> onChanged}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Text(
              label,
              style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white54 : _onSurfaceVariant.withOpacity(0.6)
              )
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 18,
            child: TextFormField(
              initialValue: value,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A)
              ),
              textAlign: TextAlign.center,
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStaticBox({required String label, required String value}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155).withOpacity(0.5) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : _onSurfaceVariant.withOpacity(0.5))),
          const SizedBox(height: 2),
          SizedBox(
            height: 18,
            child: Center(
              child: Text(
                value,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : _onSurface.withOpacity(0.6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 3 – Instrucciones de Preparación
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep3() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila: Título y Botón + en la misma línea
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _fieldLabel('NUEVA INSTRUCCIÓN'),
                  GestureDetector(
                    onTap: () {
                      final text = _prepCtrl.text.trim();
                      if (text.isNotEmpty) {
                        setState(() {
                          _pasos.add(_RecipeStep(description: text));
                          _prepCtrl.clear();
                          FocusManager.instance.primaryFocus?.unfocus();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text('AÑADIR', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // TextField ocupando todo el ancho disponible
              _textField(
                controller: _prepCtrl,
                hint: 'Ej: Dorar la cebolla y el ajo...',
                maxLines: 3,
              ),
            ],
          ),
        ),
        if (_pasos.isNotEmpty) ...[
          const SizedBox(height: 20),
          _fieldLabel('PASOS DE PREPARACIÓN'),
          const SizedBox(height: 10),
          Column(
            children: List.generate(_pasos.length, (index) => _stepItem(_pasos[index], index)),
          ),
        ],
      ],
    );
  }

  Widget _stepItem(_RecipeStep step, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white, // Color consistente
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Flechas de orden
          Column(
            children: [
              GestureDetector(
                onTap: index > 0 ? () => setState(() {
                  final item = _pasos.removeAt(index);
                  _pasos.insert(index - 1, item);
                }) : null,
                child: Icon(Icons.keyboard_arrow_up, color: index > 0 ? _primary : Colors.grey.withOpacity(0.5), size: 20),
              ),
              GestureDetector(
                onTap: index < _pasos.length - 1 ? () => setState(() {
                  final item = _pasos.removeAt(index);
                  _pasos.insert(index + 1, item);
                }) : null,
                child: Icon(Icons.keyboard_arrow_down, color: index < _pasos.length - 1 ? _primary : Colors.grey.withOpacity(0.5), size: 20),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                step.description,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white : _onSurface)
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: _error, size: 20),
            onPressed: () => setState(() => _pasos.removeAt(index)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 4 – Parámetros de Cierre y Finalización Completo Original
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            children: [
              Row(children: [
                Expanded(child: _fieldLabel('PORCIONES')),
                const SizedBox(width: 8),
                Expanded(child: _fieldLabel('PESO/PORC (gr)')),
              ]),
              Row(children: [
                Expanded(child: _textField(controller: _porcionesCtrl, hint: 'Ej: 4', keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: _textField(controller: _pesoPorcionCtrl, hint: 'Ej: 250', keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _fieldLabel('TIEMPO (min)')),
                const SizedBox(width: 8),
                Expanded(child: _fieldLabel('CALORÍAS (kcal)')),
              ]),
              Row(children: [
                Expanded(child: _textField(controller: _tiempoCtrl, hint: 'Ej: 45', keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: _textField(controller: _caloriasCtrl, hint: 'Ej: 1200', keyboardType: TextInputType.number)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('DIFICULTAD DE LA RECETA'),
              const SizedBox(height: 12),
              _dificultadSelector(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dificultadSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Obtenemos la dificultad actual basada en el ID (restando 1 para el índice)
    final currentData = _dificultadData[_dificultad];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botón -
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: _dificultad > 0 ? _primary : Colors.grey,
              onPressed: _dificultad > 0 ? () => setState(() => _dificultad--) : null,
            ),
            // Indicador visual (Puntos)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(5, (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _dificultad == index ? _primary : (isDark ? Colors.white24 : Colors.grey[300]),
                  ),
                )),
              ),
            ),
            // Botón +
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: _dificultad < 4 ? _primary : Colors.grey,
              onPressed: _dificultad < 4 ? () => setState(() => _dificultad++) : null,
            ),
          ],
        ),
        // Leyenda única
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(currentData['icon'], size: 20, color: _primary),
            const SizedBox(width: 8),
            Text(
              currentData['label'].toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : _onSurface),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dificultadTile(int value, String label, IconData icon) {
    final selected = _dificultad == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _dificultad = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? _primary
              : (isDark ? const Color(0xFF1E293B) : Colors.grey.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? _primary
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : (isDark ? Colors.white60 : _onSurfaceVariant),
              size: 20,
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.white : (isDark ? Colors.white70 : _onSurface),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white70 : _onSurfaceVariant.withOpacity(0.7),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _card({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white10 : _outline.withOpacity(0.3)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 13, color: isDark ? Colors.white : _onSurface),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          isDense: true,
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final esUltimoPaso = _step == 4;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : _surface,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          if (_step > 1) ...[
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? Colors.white24 : _outline),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => setState(() => _step--),
                child: Text(
                  'ATRÁS',
                  style: TextStyle(color: isDark ? Colors.white70 : _onSurfaceVariant, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _isSaving
                  ? null
                  : () {
                if (esUltimoPaso) {
                  _showResumenDialog();
                } else {
                  setState(() => _step++);
                }
              },
              child: _isSaving
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : Text(
                esUltimoPaso ? 'GUARDAR RECETA' : 'CONTINUAR',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField({required TextEditingController controller, required String hint, FocusNode? focusNode}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 18,
            color: isDark ? Colors.white : _onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => controller.clear()),
              child: Icon(
                Icons.close,
                size: 16,
                color: isDark ? Colors.white : _onSurfaceVariant.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }
  void _showResumenDialog() {
    final List<String> diffLabels = ['Principiante', 'Aficionado', 'Intermedio', 'Profesional', 'Experto'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resumen de la Receta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _resumenRow('Ingredientes:', '${_ingredients.length} items'),
              _resumenRow('Monto Total:', '\$${_calcularCostoTotal().toStringAsFixed(2)}'),
              _resumenRow('Instrucciones:', '${_pasos.length} pasos'),
              _resumenRow('Porciones:', '${_porcionesCtrl.text} (${_pesoPorcionCtrl.text} gr c/u)'),
              _resumenRow('Calorías:', '${_caloriasCtrl.text} kcal'),
              _resumenRow('Tiempo:', '${_tiempoCtrl.text} min'),
              _resumenRow('Dificultad:', _dificultadData[_dificultad]['label']),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _persistirRecetaFinal(); // Aquí mantienes tu lógica original de guardar
            },
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );
  }

  Widget _resumenRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );
}

extension _ElevatedOnButton on ButtonStyle {
  Widget asButton({required VoidCallback onPressed, required Widget child}) {
    return ElevatedButton(style: this, onPressed: onPressed, child: child);
  }
}
