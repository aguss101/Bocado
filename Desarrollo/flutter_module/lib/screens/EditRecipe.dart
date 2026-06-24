import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_module/models/UsuarioLogged.dart';
import 'package:flutter_module/services/Receta.dart';
import 'package:image_picker/image_picker.dart';
import '../services/UploadImg.dart';
import '../theme/Notifier.dart';
import '../theme/App.dart';
import '../widgets/Common.dart';

const _primary = AppTheme.primary;
const _error = Color(0xFFB91C1C);

const List<DropdownMenuItem<int>> _medidaDropdownItems = [
  DropdownMenuItem(value: 1, child: Text('Peso (Base 100gr)')),
  DropdownMenuItem(value: 2, child: Text('Volumen (Base 100ml)')),
  DropdownMenuItem(value: 3, child: Text('Unidad (Base 1)')),
];

String _unitForMedida(int medida) {
  switch (medida) {
    case 1: return 'gr';
    case 2: return 'ml';
    default: return 'unid';
  }
}

class _Ingredient {
  int idAlimento;
  final String name;
  final String category;
  String quantity;
  String unit;
  double priceBase;
  int idMedida;
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

class _RecipeStep {
  String description;
  _RecipeStep({required this.description});
}

class _FotoItem {
  final Uint8List? bytes;
  final String? url;

  _FotoItem.fromBytes(this.bytes) : url = null;
  _FotoItem.fromUrl(this.url) : bytes = null;
}

class RecipeEditorScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final Map<String, dynamic>? recetaExistente;
  final usuario_Logged user;
  const RecipeEditorScreen({
    super.key,
    required this.themeNotifier,
    required this.user,
    this.recetaExistente
  });

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  BocadoColors get _c => BocadoColors.of(context);
  Color get _bg => _c.bg;
  Color get _surface => _c.surface;
  Color get _outline => _c.border;
  Color get _onSurface => _c.text;
  Color get _onSurfaceVariant => _c.muted;
  Color get _inputBg => _c.surfaceContainer;
  bool get _esEdicion => widget.recetaExistente != null;
  static const MethodChannel _channel = MethodChannel('com.example.bocado/recetas');
  int _step = 1;
  int? _idRecetaActual;

  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  List<_FotoItem> _listaFotos = [];
  final int _maxFotos = 4;

  final ImagePicker _picker = ImagePicker();

  Future<void> _agregarFotos() async {
    if (_listaFotos.length >= _maxFotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya has alcanzado el límite de 4 fotos')),
      );
      return;
    }

    await _mostrarOpcionesPicker();
  }

  Future<void> _mostrarOpcionesPicker() async {
    final source = await showImageSourceSheet(context);
    if (source == null) return;
    if (source == ImageSource.camera) {
      await _tomarFotoConCamara();
    } else {
      await _subirDesdeGaleriaMultiple();
    }
  }

  Future<void> _tomarFotoConCamara() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo != null) {
      final bytes = await photo.readAsBytes();
      setState(() {
        _listaFotos.add(_FotoItem.fromBytes(bytes));
      });
    }
  }

  Future<void> _subirDesdeGaleriaMultiple() async {
    final int espaciosDisponibles = _maxFotos - _listaFotos.length;

    if (espaciosDisponibles <= 0) return;

    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 85,
    );

    if (images.isNotEmpty) {
      final List<XFile> imagenesAProcesar = images.take(espaciosDisponibles).toList();

      List<_FotoItem> nuevasFotos = [];

      for (var xFile in imagenesAProcesar) {
        final bytes = await xFile.readAsBytes();
        nuevasFotos.add(_FotoItem.fromBytes(bytes));
      }

      setState(() {
        _listaFotos.addAll(nuevasFotos);
      });
    }
  }

  final _ingSearchCtrl = TextEditingController();
  final List<_Ingredient> _ingredients = [];
  List<Map<String, dynamic>> _dbAlimentosMaster = [];
  List<Map<String, dynamic>> _suggestions = [];
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final _prepCtrl = TextEditingController();
  final List<_RecipeStep> _pasos = [];

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
  List<Map<String, dynamic>> _tagsSeleccionadas = [];
  List<Map<String, dynamic>> _tagsDisponibles = [];
  bool _esPublico = true;
  final TextEditingController _tagsSearchCtrl = TextEditingController();

  String? _validarReceta() {
    List<String> faltantes = [];

    if (_nombreCtrl.text.isEmpty) faltantes.add("- Título de la receta");
    if (_listaFotos.isEmpty) faltantes.add("- Al menos una foto");
    if (_ingredients.isEmpty) faltantes.add("- Ingredientes");
    if (_pasos.isEmpty) faltantes.add("- Pasos de preparación");
    if (_porcionesCtrl.text.isEmpty) faltantes.add("- Cantidad de porciones");
    if (_tiempoCtrl.text.isEmpty) faltantes.add("- Tiempo de cocción");
    if (faltantes.isNotEmpty) {
      return "Para publicar tu receta, primero completa:\n\n${faltantes.join('\n')}";
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _inicializarPantalla();
    _ingSearchCtrl.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) return;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            150,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Future<void> _inicializarPantalla() async {
    await Future.wait([
      _cargarAlimentosDesdeDB(),
      _cargarEtiquetasDesdeBD(),
    ]);

    if (widget.recetaExistente != null) {
      _cargarRecetaExistente(widget.recetaExistente!);
    }
  }

  void _cargarRecetaExistente(Map<String, dynamic> recetaData) {
    final String fotosRaw = recetaData['foto']?.toString() ?? '';
    final List<dynamic> fotosGuardadas = fotosRaw.isNotEmpty ? fotosRaw.split('|') : [];
    final List<_FotoItem> fotosCargadas = fotosGuardadas
        .map((url) => _FotoItem.fromUrl(url.toString()))
        .toList();

    final List<dynamic> ingredientesGuardados = (recetaData['ingredientes'] as List<dynamic>?) ?? [];
    final List<_Ingredient> ingredientesCargados = ingredientesGuardados.map((raw) {
      final Map<String, dynamic> ing = Map<String, dynamic>.from(raw as Map);

      final int idAlimento = ing['id_alimento'] is int
          ? ing['id_alimento'] as int
          : int.tryParse(ing['id_alimento'].toString()) ?? -1;
      final int idMedida = ing['id_medida'] is int
          ? ing['id_medida'] as int
          : int.tryParse(ing['id_medida'].toString()) ?? 1;
      final double cantidad = ing['cantidad'] is num
          ? (ing['cantidad'] as num).toDouble()
          : double.tryParse(ing['cantidad'].toString()) ?? 0.0;
      final double precio = ing['precio'] is num
          ? (ing['precio'] as num).toDouble()
          : double.tryParse(ing['precio'].toString()) ?? 0.0;

      final Map<String, dynamic> alimentoCatalogo = _dbAlimentosMaster.firstWhere(
            (a) => (a['id_alimento'] ?? a['id']).toString() == idAlimento.toString(),
        orElse: () => const <String, dynamic>{},
      );

      return _Ingredient(
        idAlimento: idAlimento,
        name: ing['nombre_alimento']?.toString() ?? 'Ingrediente',
        category: alimentoCatalogo['categoria']?.toString() ?? 'Añadido',
        quantity: _formatNumero(cantidad),
        unit: _unitForMedida(idMedida),
        priceBase: precio,
        idMedida: idMedida,
        idUsuario: widget.user.id,
      );
    }).toList();

    final String instruccionesRaw = recetaData['instrucciones']?.toString() ?? '';
    final List<String> pasosGuardados = instruccionesRaw.isNotEmpty ? instruccionesRaw.split('|') : [];
    final List<_RecipeStep> pasosCargados = pasosGuardados
        .map((descripcion) => _RecipeStep(description: descripcion))
        .toList();

    final List<dynamic> idsTagsGuardados = (recetaData['tags_ids'] as List<dynamic>?) ?? [];
    final List<Map<String, dynamic>> tagsCargadas = _tagsDisponibles
        .where((tag) => idsTagsGuardados.any((id) => id.toString() == tag['id'].toString()))
        .toList();

    final int idDificultadGuardado = recetaData['id_dificultad'] is int
        ? recetaData['id_dificultad'] as int
        : int.tryParse(recetaData['id_dificultad']?.toString() ?? '') ?? 1;
    final int indiceDificultad = _dificultadData.indexWhere((d) => d['id'] == idDificultadGuardado);

    final double caloriasGuardadas = recetaData['calorias_totales'] is num
        ? (recetaData['calorias_totales'] as num).toDouble()
        : double.tryParse(recetaData['calorias_totales']?.toString() ?? '') ?? 0.0;
    final double pesoPorcionGuardado = recetaData['porciones_peso'] is num
        ? (recetaData['porciones_peso'] as num).toDouble()
        : double.tryParse(recetaData['porciones_peso']?.toString() ?? '') ?? 0.0;

    setState(() {
      _idRecetaActual = int.tryParse(recetaData['id']?.toString() ?? '');
      _nombreCtrl.text = recetaData['nombre']?.toString() ?? '';
      _descripcionCtrl.text = recetaData['breve_descripcion']?.toString() ?? '';
      _listaFotos = fotosCargadas;

      _ingredients
        ..clear()
        ..addAll(ingredientesCargados);

      _pasos
        ..clear()
        ..addAll(pasosCargados);

      _tagsSeleccionadas = tagsCargadas;

      _porcionesCtrl.text = recetaData['porciones']?.toString() ?? '';
      _pesoPorcionCtrl.text = _formatNumero(pesoPorcionGuardado);
      _tiempoCtrl.text = recetaData['tiempo_coccion']?.toString() ?? '';
      _caloriasCtrl.text = _formatNumero(caloriasGuardadas);

      _dificultad = indiceDificultad >= 0 ? indiceDificultad : 1;
      _esPublico = _parseBool(recetaData['visibilidad'], defaultValue: true);
    });
  }

  bool _parseBool(dynamic valor, {required bool defaultValue}) {
    if (valor == null) return defaultValue;
    if (valor is bool) return valor;
    if (valor is num) return valor != 0;
    return valor.toString().toLowerCase() == 'true' || valor.toString() == '1';
  }

  String _formatNumero(double valor) {
    if (valor == 0) return '';
    if (valor == valor.roundToDouble()) return valor.toInt().toString();
    return valor.toString();
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
    _tagsSearchCtrl.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarAlimentosDesdeDB() async {
    try {
      final List<dynamic>? res = await _channel.invokeMethod('getAlimentos');
      if (res != null) {
        setState(() {
          _dbAlimentosMaster = res.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      _snack('Error al sincronizar catálogo de alimentos: $e');
    }
  }

  Future<void> _cargarEtiquetasDesdeBD() async {
    try {
      final Map<String, dynamic> params = {'id_usuario': widget.user.id};

      final List<dynamic>? res = await _channel.invokeMethod('getEtiquetas', params);

      if (res != null) {
        setState(() {
          _tagsDisponibles = res.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      _snack('Error al sincronizar etiquetas: $e');
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

  double _calcularCostoTotal() {
    return _ingredients.fold<double>(0.0, (sum, item) {
      final double sub = item.subtotal;
      if (sub <= 0) {return sum;}
      return sum + sub;
    });
  }

  Future<void> _persistirRecetaFinal({bool esBorrador = false}) async {
    if (!esBorrador) {
      final error = _validarReceta();
      if (error != null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('⚠️ Faltan datos'),
            content: Text(error),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ENTENDIDO')
              )
            ],
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      for (var ing in _ingredients) {
        if (ing.idAlimento <= 0) {
          final response = Map<String, dynamic>.from(
            await const MethodChannel('com.example.bocado/recetas')
                .invokeMethod('addAlimento', {'nombre': ing.name, 'id_usuario': widget.user.id}),
          );
          ing.idAlimento = response['id'] as int;
        }
      }

      List<String> urlsFotos = [];
      for (var foto in _listaFotos) {
        if (foto.url != null) {
          urlsFotos.add(foto.url!);
          continue;
        }
        String? url = await ImageUploadService.uploadRecetaImage(
            'user_${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}_${_listaFotos.indexOf(foto)}',
            foto.bytes!
        );
        if (url != null) urlsFotos.add(url);
      }

      List<int> idsTags = _tagsSeleccionadas.map((t) => t['id'] as int).toList();

      final Map<String, dynamic> recetaData = {
        "id": _idRecetaActual,
        'id_usuario': widget.user.id,
        'nombre': _nombreCtrl.text,
        'fotos': urlsFotos,
        'visibilidad': _esPublico,
        'es_borrador': esBorrador,
        'tags_ids': idsTags,
        'calorias_totales': double.tryParse(_caloriasCtrl.text) ?? 0.0,
        'porciones': int.tryParse(_porcionesCtrl.text) ?? 1,
        'porciones_peso': double.tryParse(_pesoPorcionCtrl.text) ?? 0.0,
        'id_dificultad': _dificultadData[_dificultad]['id'],
        'instrucciones': _pasos.map((s) => s.description).toList(),
        'precio': _calcularCostoTotal(),
        'tiempo_coccion': _tiempoCtrl.text,
        'breve_descripcion': _descripcionCtrl.text,

        'ingredientes': _ingredients.map((ing) => {
          'id_alimento': ing.idAlimento,
          'nombre': ing.name,
          'cantidad': double.tryParse(ing.quantity) ?? 0.0,
          'precio': ing.priceBase,
          'id_medida': ing.idMedida,
        }).toList(),
      };

      if(_idRecetaActual != null){
        await RecetaService.updateReceta(recetaData);
      }else{
        await RecetaService.saveReceta(recetaData);
      }

      _snack(esBorrador ? 'Borrador guardado' : 'Receta publicada con éxito');
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

  @override
  Widget build(BuildContext context) {
    final fondoPantalla = _bg;
    final fondoTarjetas = _surface;
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.92),
        border: Border(bottom: BorderSide(color: _outline)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _onSurfaceVariant),
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
                color: _onSurface,
                letterSpacing: -0.5
            ),
          ),
          const Spacer(),
          ThemeToggleButton(themeNotifier: widget.themeNotifier),
          _pillButton(icon: Icons.visibility_outlined, label: '', onTap: () {}),
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
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: _onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _esEdicion ? 'EDITANDO RECETA' : 'NUEVA RECETA',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: _primary, letterSpacing: 2),
          ),
          Text(
            'Paso $_step de 4',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _onSurface, height: 1.0),
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

  Widget _buildStep1() {
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
                          color: _onSurface
                      )
                  ),
                  Text('${_listaFotos.length}/$_maxFotos FOTOS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _primary, letterSpacing: 1.5)),
                ],
              ),
              const SizedBox(height: 14),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _listaFotos.length < _maxFotos ? _listaFotos.length + 1 : _maxFotos,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  if (index == _listaFotos.length) {
                    return GestureDetector(
                      onTap: _agregarFotos,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _outline.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFFCBD5E1), size: 28),
                      ),
                    );
                  }

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _listaFotos[index].bytes != null
                            ? Image.memory(_listaFotos[index].bytes!, fit: BoxFit.cover)
                            : BocadoNetworkImage(url: _listaFotos[index].url!, memCacheWidth: 300),
                      ),
                      Positioned(
                        top: 4, right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _listaFotos.removeAt(index)),
                          child: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),
              Center(
                  child: Text(
                      'JPG, PNG • Máx 10 MB por foto',
                      style: TextStyle(fontSize: 10, color: _onSurfaceVariant.withValues(alpha: 0.6)),
                      textAlign: TextAlign.center
                  )
              ),
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
              _searchField(controller: _ingSearchCtrl, hint: 'Buscar ingrediente...'),

              if (_ingSearchCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('SUGERENCIAS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: _onSurfaceVariant.withValues(alpha: 0.5), letterSpacing: 2)),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _customIngredientRow(_ingSearchCtrl.text.trim()),
                        const Divider(height: 8, thickness: 0.5),
                        ..._suggestions.map((s) => _suggestionRow(s)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.06),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('LISTA DE INGREDIENTES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _primary, letterSpacing: 2)),
                    Text('${_ingredients.length} ITEMS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _onSurfaceVariant.withValues(alpha: 0.6), letterSpacing: 1.5)),
                  ],
                ),
              ),
              ..._ingredients.asMap().entries.map((e) => _ingredientRow(e.value, e.key)),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _inputBg,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL RECETA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _onSurfaceVariant.withValues(alpha: 0.7))),
                    Text('\$${_calcularCostoTotal().toStringAsFixed(2)}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _onSurface, letterSpacing: -0.5)),
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
    return GestureDetector(
      onTap: () {
        double precioNum = 0.00;
        if (s['sub'] != null) {
          final String subString = s['sub'].toString();
          if (subString.contains('•')) {
            final partePrecio = subString.split('•').last.replaceAll(RegExp(r'[^\d.]'), '').trim();
            precioNum = double.tryParse(partePrecio) ?? 0.00;
          } else {
            precioNum = double.tryParse(subString.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.00;
          }
        } else if (s['precio'] != null) {
          precioNum = double.tryParse(s['precio'].toString()) ?? 0.00;
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
                quantity: '0',
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
                color: _primary.withValues(alpha: 0.1),
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
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _onSurface
                    ),
                  ),
                  Text(
                    s['sub']?.toString() ?? s['categoria']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: _onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.add, color: _primary.withValues(alpha: 0.8), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _ingredientRow(_Ingredient ing, int index) {
    final textColor = _onSurface;
    final subtextColor = _onSurfaceVariant.withValues(alpha: 0.5);
    final double currentSubtotal = ing.subtotal;
    final bool isInvalid = currentSubtotal <=0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: Column(
        children: [
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
                    isInvalid ? "Inválido" :
                    '\$${ing.subtotal.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: textColor),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _ingredients.removeAt(index)),
                    child: Icon(Icons.delete_outline, color: _error.withValues(alpha: 0.6), size: 18),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 50, height: 26,
                    child: TextFormField(
                      controller: TextEditingController(text: ing.quantity == "0" ? "" : ing.quantity),

                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                      onFieldSubmitted: (v) {
                        FocusScope.of(context).unfocus();
                        final normalized = v.replaceAll(",", ".");
                        final parsed = double.tryParse(normalized);

                        setState(() {
                          ing.quantity = (parsed != null && parsed > 0) ? normalized : "0";
                        });
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

  void _showIngredientDialog({_Ingredient? ing, String? newName}) {
    final isEditing = ing != null;
    final TextEditingController cantCtrl = TextEditingController(text: isEditing ? ing.quantity : '100');
    final TextEditingController precioCtrl = TextEditingController(text: isEditing ? ((double.tryParse(ing.quantity) ?? 1) * (ing.priceBase / (ing.idMedida < 3 ? 100 : 1))).toStringAsFixed(2) : '');
    int medida = isEditing ? ing.idMedida : 1;

    String getSufijo(int medida) {
      switch (medida) {
        case 1: return 'gramos';
        case 2: return 'mililitros';
        case 3: return 'unidades';
        default: return '';
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Editar: ${ing.name}' : 'Configurar: $newName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: medida,
                items: _medidaDropdownItems,
                onChanged: (v) => setDialogState(() => medida = v!),
              ),
              TextField(
                controller: cantCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cantidad Comprada',
                  suffixText: getSufijo(medida),
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              TextField(
                controller: precioCtrl,
                decoration: const InputDecoration(labelText: 'Precio Total Pagado \$'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {

                setState(() {
                  double cantComprada = double.tryParse(cantCtrl.text) ?? 0;
                  double precioTotal = double.tryParse(precioCtrl.text) ?? 0;

                  if (cantComprada <= 0) return;

                  double nuevoPriceBase = (precioTotal / cantComprada);
                  if (medida == 1 || medida == 2) nuevoPriceBase *= 100;

                  if (isEditing) {
                    ing.priceBase = nuevoPriceBase;
                    ing.idMedida = medida;
                    ing.unit = _unitForMedida(medida);
                  } else {
                    _ingredients.add(_Ingredient(
                        idAlimento: DateTime.now().millisecondsSinceEpoch,
                        name: newName!,
                        category: 'Personalizado',
                        quantity: cantCtrl.text,
                        unit: _unitForMedida(medida),
                        priceBase: nuevoPriceBase,
                        idMedida: medida,
                        idUsuario: widget.user.id
                    ));
                    _ingSearchCtrl.clear();
                  }
                });
                Navigator.pop(context);
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
          color: _primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _primary.withValues(alpha: 0.15)),
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
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _onSurfaceVariant.withValues(alpha: 0.6)),
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
    final cantCompraCtrl = TextEditingController();
    final precioTotalCtrl = TextEditingController();
    int medidaSeleccionada = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Configurar: $name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: medidaSeleccionada,
                items: _medidaDropdownItems,
                onChanged: (v) => setDialogState(() => medidaSeleccionada = v!),
              ),
              TextField(controller: cantCompraCtrl, decoration: const InputDecoration(labelText: 'Cantidad comprada'), keyboardType: TextInputType.number),
              TextField(controller: precioTotalCtrl, decoration: const InputDecoration(labelText: 'Precio pagado \$'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                double cant = double.tryParse(cantCompraCtrl.text) ?? 0;
                double total = double.tryParse(precioTotalCtrl.text) ?? 0;
                if (cant <= 0) return;

                double precioBaseCalculado = (total / cant);
                if (medidaSeleccionada == 1 || medidaSeleccionada == 2) {
                  precioBaseCalculado *= 100;
                }

                setState(() {
                  _ingredients.add(_Ingredient(
                    idAlimento: -1,
                    name: name,
                    category: 'Personalizado',
                    quantity: '100',
                    unit: _unitForMedida(medidaSeleccionada),
                    priceBase: precioBaseCalculado,
                    idMedida: medidaSeleccionada,
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

  Widget _buildStep3() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _outline),
      ),
      child: Row(
        children: [
          Column(
            children: [
              GestureDetector(
                onTap: index > 0 ? () => setState(() {
                  final item = _pasos.removeAt(index);
                  _pasos.insert(index - 1, item);
                }) : null,
                child: Icon(Icons.keyboard_arrow_up, color: index > 0 ? _primary : Colors.grey.withValues(alpha: 0.5), size: 20),
              ),
              GestureDetector(
                onTap: index < _pasos.length - 1 ? () => setState(() {
                  final item = _pasos.removeAt(index);
                  _pasos.insert(index + 1, item);
                }) : null,
                child: Icon(Icons.keyboard_arrow_down, color: index < _pasos.length - 1 ? _primary : Colors.grey.withValues(alpha: 0.5), size: 20),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                step.description,
                style: TextStyle(fontSize: 13, color: _onSurface)
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

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('ETIQUETAS'),
              const SizedBox(height: 8),
              Autocomplete<Map<String, dynamic>>(

                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  _tagsSearchCtrl.addListener(() {
                    if (_tagsSearchCtrl.text.isEmpty && controller.text.isNotEmpty) {
                      controller.text = "";
                    }
                  });
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Escribe para buscar...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                },

                optionsBuilder: (TextEditingValue textEditingValue) {
                  final query = textEditingValue.text.toLowerCase();

                  if (query.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                  return _tagsDisponibles.where((tag) {
                    final matchesQuery = tag['nombre'].toString().toLowerCase().contains(query);
                    final isAlreadySelected = _tagsSeleccionadas.any((t) => t['id'] == tag['id']);

                    return matchesQuery && !isAlreadySelected;
                  });
                },

                displayStringForOption: (option) => option['nombre'],

                onSelected: (selection) {
                  setState(() {
                    _tagsSearchCtrl.clear();
                    FocusScope.of(context).unfocus();

                    if (!_tagsSeleccionadas.any((t) => t['id'] == selection['id'])) {
                      _tagsSeleccionadas.add(selection);
                    }
                  });
                },

                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        height: 200,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: options.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              title: Text(
                                option['nombre'],
                                style: const TextStyle(fontSize: 14),
                              ),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _tagsSeleccionadas.map((tagMap) => Chip(
                  label: Text(tagMap['nombre']),
                  onDeleted: () => setState(() => _tagsSeleccionadas.remove(tagMap)),
                  backgroundColor: _primary.withValues(alpha: 0.1),
                )).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
        const SizedBox(height: 12),
        _card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _onSurface,
                  ),
                  children: [
                    const TextSpan(text: 'VISIBILIDAD: '),
                    TextSpan(
                      text: _esPublico ? 'PÚBLICA' : 'PRIVADA',
                      style: TextStyle(
                        color: _esPublico ? _primary : Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _esPublico,
                activeThumbColor: _primary,
                onChanged: (val) => setState(() => _esPublico = val),
              ),
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
    final currentData = _dificultadData[_dificultad];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: _dificultad > 0 ? _primary : Colors.grey,
              onPressed: _dificultad > 0 ? () => setState(() => _dificultad--) : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(5, (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _dificultad == index ? _primary : _outline,
                  ),
                )),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: _dificultad < 4 ? _primary : Colors.grey,
              onPressed: _dificultad < 4 ? () => setState(() => _dificultad++) : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(currentData['icon'], size: 20, color: _primary),
            const SizedBox(width: 8),
            Text(
              currentData['label'].toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, color: _onSurface),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: _onSurfaceVariant.withValues(alpha: 0.7),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _outline.withValues(alpha: 0.3)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 13, color: _onSurface),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          isDense: true,
          hintStyle: TextStyle(color: _onSurfaceVariant, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final esUltimoPaso = _step == 4;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _outline)),
      ),
      child: Row(
        children: [
          if (_step > 1) ...[
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _outline),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => setState(() => _step--),
                child: Text(
                  'ATRÁS',
                  style: TextStyle(color: _onSurfaceVariant, fontWeight: FontWeight.bold),
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
                esUltimoPaso ? (_esEdicion ? 'ACTUALIZAR RECETA' : 'GUARDAR RECETA') : 'CONTINUAR',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField({required TextEditingController controller, required String hint, FocusNode? focusNode}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _outline,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 18,
            color: _onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              style: TextStyle(
                fontSize: 13,
                color: _onSurface,
              ),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(color: _onSurfaceVariant),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => controller.clear()),
              child: Icon(
                Icons.close,
                size: 16,
                color: _onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }
  void _showResumenDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resumen de la Receta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _resumenRow('Imágenes:', '${_listaFotos.length} fotos'),
              _resumenRow('Ingredientes:', '${_ingredients.length} items'),
              _resumenRow('Monto Total:', '\$${_calcularCostoTotal().toStringAsFixed(2)}'),
              _resumenRow('Instrucciones:', '${_pasos.length} pasos'),
              _resumenRow('Etiquetas:', '${_tagsSeleccionadas.length} seleccionadas'),
              _resumenRow('Porciones:', '${_porcionesCtrl.text} (${_pesoPorcionCtrl.text} gr c/u)'),
              _resumenRow('Calorías:', '${_caloriasCtrl.text} kcal'),
              _resumenRow('Tiempo:', '${_tiempoCtrl.text} min'),
              _resumenRow('Dificultad:', _dificultadData[_dificultad]['label']),
              _resumenRow('Visibilidad:', _esPublico ? 'Pública' : 'Privada'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR')
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _persistirRecetaFinal(esBorrador: true);
            },
            child: const Text('BORRADOR'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _persistirRecetaFinal(esBorrador: false);
            },
            child: Text( (_idRecetaActual == null) ? 'CONFIRMAR' : 'PUBLICAR'),
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