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
  final MethodChannel _channel = const MethodChannel('com.example.bocado/recetas');

  int _step = 1;

  // Step 1 controllers
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();

  // Step 2 controllers
  final TextEditingController _buscarCtrl = TextEditingController();
  List<dynamic> _catalogo = [];
  List<dynamic> _filtrados = [];
  List<Map<String, dynamic>> _ingredientes = [];
  final Map<int, TextEditingController> _cantidadControllers = {};
  final Map<int, TextEditingController> _precioControllers = {};

  // Step 3 controllers
  final TextEditingController _prepCtrl = TextEditingController();
  List<String> _pasos = [];

  // Step 4 controllers
  final TextEditingController _porcionesCtrl = TextEditingController();
  final TextEditingController _pesoCtrl = TextEditingController();
  final TextEditingController _tiempoCtrl = TextEditingController();
  String _pesoUnidad = "g";
  String _dificultad = "Intermedio";

  @override
  void initState() {
    super.initState();
    _cargarAlimentos();
    _buscarCtrl.addListener(() => _filtrar(_buscarCtrl.text));
  }

  Future<void> _cargarAlimentos() async {
    try {
      final res = await _channel.invokeMethod("getAlimentos");
      setState(() => _catalogo = res ?? []);
    } catch (e) {
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
    setState(() => _filtrados = resultados);
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
        backgroundColor: error ? Colors.red : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _buscarCtrl.dispose();
    _prepCtrl.dispose();
    _porcionesCtrl.dispose();
    _pesoCtrl.dispose();
    _tiempoCtrl.dispose();
    _cantidadControllers.values.forEach((c) => c.dispose());
    _precioControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;
    final outline = isDark ? AppTheme.outlineDark : AppTheme.outlineLight;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0701) : const Color(0xFFFFFBF5),
      body: Column(
        children: [
          // Header
          _buildHeader(isDark, outline),

          // Step Indicator
          _buildStepIndicator(isDark),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _buildStepContent(isDark, secondary, outline),
              ),
            ),
          ),

          // Footer Navigation
          _buildFooter(isDark, outline),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color outline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0701) : Colors.white,
        border: Border(bottom: BorderSide(color: outline.withOpacity(0.2))),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              color: isDark ? Colors.white : AppTheme.onSurfaceLight,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Editor de Recetas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.onSurfaceLight,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('VISTA PREVIA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : AppTheme.secondaryLight,
                side: BorderSide(color: outline.withOpacity(0.3)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            'PASO $_step DE 4',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final isActive = i + 1 <= _step;
              final isCurrent = i + 1 == _step;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isCurrent ? 64 : 32,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primary : (isDark ? Colors.white10 : Colors.black12),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: isCurrent
                      ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8)]
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(bool isDark, Color secondary, Color outline) {
    switch (_step) {
      case 1:
        return _buildStep1(isDark, secondary, outline);
      case 2:
        return _buildStep2(isDark, secondary, outline);
      case 3:
        return _buildStep3(isDark, secondary, outline);
      default:
        return _buildStep4(isDark, secondary, outline);
    }
  }

  Widget _buildStep1(bool isDark, Color secondary, Color outline) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1108) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outline.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('TÍTULO DE LA RECETA'),
                const SizedBox(height: 12),
                TextField(
                  controller: _nombreCtrl,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.onSurfaceLight,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ej: Risotto de Azafrán y Setas Silvestres',
                    hintStyle: TextStyle(color: secondary.withOpacity(0.5)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0D0701) : const Color(0xFFFFFBF5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: outline.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: outline.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildLabel('BREVE DESCRIPCIÓN'),
                const SizedBox(height: 12),
                TextField(
                  controller: _descripcionCtrl,
                  maxLines: 8,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : AppTheme.onSurfaceLight,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cuenta la historia detrás de este plato...',
                    hintStyle: TextStyle(color: secondary.withOpacity(0.5)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0D0701) : const Color(0xFFFFFBF5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: outline.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: outline.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1108) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outline.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Galería de fotos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.onSurfaceLight,
                      ),
                    ),
                    Text(
                      'MÍNIMO 1 FOTO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary.withOpacity(0.6),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildPhotoUploader(isDark, outline),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(bool isDark, Color secondary, Color outline) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1108) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outline.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('AÑADIR INGREDIENTE'),
                const SizedBox(height: 16),
                TextField(
                  controller: _buscarCtrl,
                  style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurfaceLight),
                  decoration: InputDecoration(
                    hintText: 'Buscar ingrediente...',
                    hintStyle: TextStyle(color: secondary.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search, color: AppTheme.primary),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0D0701) : const Color(0xFFFFFBF5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_filtrados.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filtrados.length,
                      itemBuilder: (_, i) {
                        final a = _filtrados[i];
                        final yaAgregado = _ingredientes.any((e) => e["id"] == a["id"]);
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.restaurant_menu, color: AppTheme.primary, size: 20),
                          ),
                          title: Text(
                            a["nombre"],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.onSurfaceLight,
                            ),
                          ),
                          trailing: yaAgregado
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                          onTap: yaAgregado ? null : () => _agregar(a),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 7,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1108) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outline.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('LISTA DE INGREDIENTES'),
                    Text(
                      '${_ingredientes.length} ITEMS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: secondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ingredientes.length,
                  separatorBuilder: (_, __) => Divider(color: outline.withOpacity(0.1)),
                  itemBuilder: (_, i) {
                    final ing = _ingredientes[i];
                    final cantidadCtrl = _cantidadControllers.putIfAbsent(
                      ing["id"],
                          () => TextEditingController(text: ing["cantidad"].toString()),
                    );
                    final precioCtrl = _precioControllers.putIfAbsent(
                      ing["id"],
                          () => TextEditingController(text: ing["precio"].toString()),
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ing["nombre"],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppTheme.onSurfaceLight,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => setState(() => _ingredientes.removeAt(i)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildSmallTextField(
                                  'CANTIDAD',
                                  cantidadCtrl,
                                      (v) => ing["cantidad"] = int.tryParse(v) ?? 0,
                                  isDark,
                                  outline,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropdown(
                                  'UNIDAD',
                                  ing["medida"],
                                  ["g", "kg", "ml", "u"],
                                      (v) => setState(() => ing["medida"] = v),
                                  isDark,
                                  outline,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: _buildSmallTextField(
                                  'PRECIO',
                                  precioCtrl,
                                      (v) => ing["precio"] = int.tryParse(v) ?? 0,
                                  isDark,
                                  outline,
                                  prefix: '\$',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(bool isDark, Color secondary, Color outline) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 8,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1108) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: outline.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'NUEVA INSTRUCCIÓN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppTheme.onSurfaceLight,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _prepCtrl,
                      maxLines: 4,
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurfaceLight),
                      decoration: InputDecoration(
                        hintText: 'Describe la técnica, temperatura y tiempos...',
                        hintStyle: TextStyle(color: secondary.withOpacity(0.5)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0D0701) : const Color(0xFFFFFBF5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: outline.withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: outline.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_prepCtrl.text.trim().isNotEmpty) {
                            setState(() {
                              _pasos.add(_prepCtrl.text.trim());
                              _prepCtrl.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('AGREGAR PASO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1108) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: outline.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('PASOS ACTUALES'),
                    const SizedBox(height: 20),
                    _pasos.isEmpty
                        ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          'No hay pasos agregados',
                          style: TextStyle(color: secondary),
                        ),
                      ),
                    )
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pasos.length,
                      itemBuilder: (_, i) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0D0701).withOpacity(0.5)
                                : const Color(0xFFFFFBF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: outline.withOpacity(0.1)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _pasos[i],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : AppTheme.secondaryLight,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => setState(() => _pasos.removeAt(i)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1108) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outline.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('AYUDA RÁPIDA'),
                const SizedBox(height: 20),
                _buildTip('Describe acciones concretas con verbos en infinitivo'),
                const SizedBox(height: 16),
                _buildTip('Indica tiempos aproximados de reposo o cocción'),
                const SizedBox(height: 16),
                _buildTip('Menciona la textura o color ideal'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4(bool isDark, Color secondary, Color outline) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1108) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outline.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField('PORCIONES', _porcionesCtrl, isDark, outline),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildNumberField('PESO POR PORCIÓN (G)', _pesoCtrl, isDark, outline),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField('TIEMPO (MIN)', _tiempoCtrl, isDark, outline),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildNumberField('CALORÍAS (KCAL)', TextEditingController(), isDark, outline),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildLabel('DIFICULTAD'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDifficultyButton('Principiante', Icons.egg_alt, isDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDifficultyButton('Intermedio', Icons.restaurant, isDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDifficultyButton('Experto', Icons.local_fire_department, isDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1108) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outline.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Resumen de la receta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.onSurfaceLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSummaryRow('Ingredientes', '${_ingredientes.length} items', secondary),
                _buildSummaryRow('Pasos', '${_pasos.length} pasos', secondary),
                _buildSummaryRow('Tiempo', '${_tiempoCtrl.text.isEmpty ? "0" : _tiempoCtrl.text} min', secondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark, Color outline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0701) : Colors.white,
        border: Border(top: BorderSide(color: outline.withOpacity(0.2))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_step > 1)
              TextButton.icon(
                onPressed: () => setState(() => _step--),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('VOLVER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : AppTheme.secondaryLight,
                ),
              )
            else
              const SizedBox(),
            ElevatedButton.icon(
              onPressed: () {
                if (_step < 4) {
                  setState(() => _step++);
                } else {
                  _snack('Guardar pendiente');
                }
              },
              icon: _step < 4 ? const Icon(Icons.arrow_forward, size: 16) : const Icon(Icons.save, size: 16),
              label: Text(
                _step < 4 ? 'SIGUIENTE' : 'GUARDAR',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppTheme.primary.withOpacity(0.7),
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildPhotoUploader(bool isDark, Color outline) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {},
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D0701) : const Color(0xFFFFFBF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: outline.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_photo_alternate, color: AppTheme.primary, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SUBIR FOTO PRINCIPAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: List.generate(4, (i) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D0701) : const Color(0xFFFFFBF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: outline.withOpacity(0.2)),
              ),
              child: Icon(Icons.add_a_photo, color: outline.withOpacity(0.4)),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSmallTextField(
      String label,
      TextEditingController controller,
      Function(String) onChanged,
      bool isDark,
      Color outline, {
        String? prefix,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppTheme.onSurfaceLight,
          ),
          decoration: InputDecoration(
            prefixText: prefix,
            filled: true,
            fillColor: isDark ? const Color(0xFF0D0701) : const Color(0xFFFFFBF5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: outline.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: outline.withOpacity(0.2)),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
      String label,
      String value,
      List<String> items,
      Function(String?) onChanged,
      bool isDark,
      Color outline,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppTheme.onSurfaceLight,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF0D0701) : const Color(0xFFFFFBF5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: outline.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: outline.withOpacity(0.2)),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.secondaryDark,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller, bool isDark, Color outline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurfaceLight),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF0D0701) : const Color(0xFFFFFBF5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outline.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outline.withOpacity(0.2)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyButton(String label, IconData icon, bool isDark) {
    final isSelected = _dificultad == label;
    return GestureDetector(
      onTap: () => setState(() => _dificultad = label),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.1)
              : (isDark ? const Color(0xFF0D0701).withOpacity(0.5) : const Color(0xFFFFFBF5)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : (isDark ? Colors.white10 : AppTheme.outlineLight.withOpacity(0.3)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : (isDark ? Colors.white54 : AppTheme.secondaryLight)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.primary : (isDark ? Colors.white70 : AppTheme.secondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color secondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: secondary,
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}