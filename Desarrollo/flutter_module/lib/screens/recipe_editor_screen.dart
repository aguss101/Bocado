import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_module/models/usuario_Logged.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const _primary = Color(0xFFD96E11);
const _primaryLight = Color(0xFFFFDBC9);
const _bg = Color(0xFFFFFBF5);
const _surface = Color(0xFFFFFFFF);
const _surfaceDim = Color(0xFFF5F5F5);
const _outline = Color(0xFFE8CCB1);
const _onSurface = Color(0xFF0F172A);
const _onSurfaceVariant = Color(0xFF475569);
const _error = Color(0xFFB91C1C);

// ─── Ingredient model ────────────────────────────────────────────────────────
class _Ingredient {
  String name;
  String category;
  String quantity;
  String unit;
  String price;
  _Ingredient({
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
  final MethodChannel _channel = const MethodChannel("bocado_channel");

  int _step = 1;

  // Step 1
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  // Step 2
  final _ingSearchCtrl = TextEditingController();
  final List<_Ingredient> _ingredients = [
    _Ingredient(
        name: 'Harina de Fuerza',
        category: 'Despensa Básica',
        quantity: '500',
        unit: 'gr',
        price: '€0.85'),
    _Ingredient(
        name: 'Sal de Maldon',
        category: 'Condimento',
        quantity: '10',
        unit: 'gr',
        price: '€0.12'),
    _Ingredient(
        name: 'Levadura Fresca',
        category: 'Fermento',
        quantity: '25',
        unit: 'gr',
        price: '€0.45'),
  ];
  final List<Map<String, String>> _suggestions = [
    {'name': 'Azafrán de hebra', 'sub': 'Premium • €420.00/kg'},
    {'name': 'Aceite de Oliva Extra', 'sub': 'Base • €12.50/L'},
  ];

  // Step 3
  final _prepCtrl = TextEditingController();
  final List<_RecipeStep> _pasos = [
    _RecipeStep(
        description:
        'Precalentar el horno a 200°C y preparar una bandeja con papel manteca. Tamizar la harina junto con el azafrán en polvo para asegurar una distribución uniforme del aroma.'),
    _RecipeStep(
        description:
        'Incorporar la manteca fría cortada en cubos pequeños y trabajar con las yemas de los dedos hasta obtener un arenado fino. Es crucial no sobrecalentar la masa.'),
  ];

  // Step 4
  final _porcionesCtrl = TextEditingController();
  final _pesoPorcionCtrl = TextEditingController();
  final _tiempoCtrl = TextEditingController();
  final _caloriasCtrl = TextEditingController();
  int _dificultad = 1; // 0 Principiante, 1 Intermedio, 2 Experto

  @override
  void dispose() {
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

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
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
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildStep(),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ─── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _surface.withOpacity(0.92),
        border:
        Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: _onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant_menu,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Bocado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          _pillButton(
            icon: Icons.visibility_outlined,
            label: 'VISTA PREVIA',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _pillButton(
      {required IconData icon,
        required String label,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border:
          Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: _onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: _onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step indicator ─────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            'EDITOR DE RECETAS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: _primary.withOpacity(0.8),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Paso $_step de 4',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _onSurface,
              letterSpacing: -0.5,
            ),
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
                  boxShadow: active
                      ? [
                    BoxShadow(
                      color: _primary.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                      : [],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Step router ────────────────────────────────────────────────────────────
  Widget _buildStep() {
    switch (_step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1 – Título, descripción y galería
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep1() {
    return Column(
      children: [
        // Basic info card
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('TÍTULO DE LA RECETA'),
              const SizedBox(height: 8),
              _textField(
                controller: _nombreCtrl,
                hint: 'Ej: Risotto de Azafrán y Setas Silvestres',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 20),
              _fieldLabel('BREVE DESCRIPCIÓN'),
              const SizedBox(height: 8),
              _textField(
                controller: _descripcionCtrl,
                hint:
                'Cuenta la historia detrás de este plato, su origen o qué lo hace especial...',
                maxLines: 5,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Gallery card
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Galería de fotos',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _onSurface,
                    ),
                  ),
                  Text(
                    'MÍNIMO 1 FOTO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: _primary.withOpacity(0.6),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Main upload button
              GestureDetector(
                onTap: () => _snack('Seleccionar foto principal'),
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: _surfaceDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _outline.withOpacity(0.6),
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignInside),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined,
                            color: _primary, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SUBIR FOTO PRINCIPAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: _onSurfaceVariant.withOpacity(0.8),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Thumbnail row
              Row(
                children: List.generate(
                    3,
                        (i) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                        height: 72,
                        decoration: BoxDecoration(
                          color: _surfaceDim,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _outline.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.add_a_photo_outlined,
                            color: Color(0xFFCBD5E1), size: 22),
                      ),
                    )),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'JPG, PNG • Máx 10 MB • Recomendamos luz natural',
                  style: TextStyle(
                    fontSize: 10,
                    color: _onSurfaceVariant.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 2 – Ingredientes
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep2() {
    return Column(
      children: [
        // Search & add card
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('AÑADIR INGREDIENTE'),
              const SizedBox(height: 10),
              _searchField(
                controller: _ingSearchCtrl,
                hint: 'Buscar ingrediente...',
              ),
              const SizedBox(height: 14),
              Text(
                'SUGERENCIAS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: _onSurfaceVariant.withOpacity(0.5),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              ..._suggestions.map((s) => _suggestionRow(s)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Ingredient list card
        _card(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.06),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  border: Border(
                      bottom: BorderSide(
                          color: Colors.black.withOpacity(0.05))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LISTA DE INGREDIENTES',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: _primary,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      '${_ingredients.length} ITEMS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: _onSurfaceVariant.withOpacity(0.6),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Rows
              ..._ingredients.asMap().entries.map((e) {
                final i = e.key;
                final ing = e.value;
                return _ingredientRow(ing, i);
              }),
              // Total
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _surfaceDim,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16)),
                  border: Border(
                      top: BorderSide(
                          color: Colors.black.withOpacity(0.05))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COSTO ESTIMADO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: _onSurfaceVariant.withOpacity(0.6),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Basado en precios de mercado',
                          style: TextStyle(
                            fontSize: 10,
                            color: _onSurfaceVariant.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: _primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Text(
                          '€1.42',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: _onSurface,
                            letterSpacing: -1,
                          ),
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

  Widget _suggestionRow(Map<String, String> s) {
    return GestureDetector(
      onTap: () => _snack('Añadido: ${s['name']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.transparent),
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
              child: const Icon(Icons.restaurant_menu,
                  color: _primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['name']!,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _onSurface)),
                  Text(s['sub']!,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _onSurfaceVariant.withOpacity(0.6),
                          letterSpacing: 0.5)),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ing.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _onSurface)),
                Text(ing.category,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _onSurfaceVariant.withOpacity(0.6),
                        letterSpacing: 1)),
              ],
            ),
          ),
          // Quantity box
          _miniInputBox(label: 'CANT.', value: ing.quantity),
          const SizedBox(width: 6),
          // Unit box
          _miniStaticBox(label: 'UNID.', value: ing.unit),
          const SizedBox(width: 10),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('PRECIO',
                  style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: _onSurfaceVariant.withOpacity(0.5),
                      letterSpacing: 0.5)),
              Text(ing.price,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: _onSurface)),
            ],
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => setState(() => _ingredients.removeAt(index)),
            child: Icon(Icons.delete_outline,
                color: _onSurfaceVariant.withOpacity(0.4), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _miniInputBox({required String label, required String value}) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceDim,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: _primary,
                  letterSpacing: 0.5)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _onSurface)),
        ],
      ),
    );
  }

  Widget _miniStaticBox({required String label, required String value}) {
    return Container(
      width: 42,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceDim,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: _primary,
                  letterSpacing: 0.5)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _onSurface)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 3 – Preparación
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep3() {
    return Column(
      children: [
        // Add step card
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.edit_note, color: _primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'NUEVA INSTRUCCIÓN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: _onSurface,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'AÑADIR DETALLES',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _onSurfaceVariant.withOpacity(0.4),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _prepCtrl,
                hint:
                'Describe la técnica, temperatura y tiempos específicos para este paso...',
                maxLines: 4,
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    if (_prepCtrl.text.trim().isNotEmpty) {
                      setState(() {
                        _pasos.add(_RecipeStep(
                            description: _prepCtrl.text.trim()));
                        _prepCtrl.clear();
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'AGREGAR PASO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Steps list
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PASOS ACTUALES',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: _onSurfaceVariant.withOpacity(0.5),
                letterSpacing: 2,
              ),
            ),
            Text(
              'REORGANIZAR',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: _primary,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._pasos.asMap().entries.map((e) => _stepCard(e.key, e.value)),
        const SizedBox(height: 16),
        // Tips card
        _card(
          color: _surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AYUDA RÁPIDA',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: _onSurfaceVariant.withOpacity(0.4),
                  letterSpacing: 2,
                ),
              ),
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _primary.withOpacity(0.2)),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: _primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              step.description,
              style: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: _onSurfaceVariant.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              GestureDetector(
                onTap: () {},
                child: Icon(Icons.edit_outlined,
                    size: 18, color: _onSurfaceVariant.withOpacity(0.35)),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _pasos.removeAt(index)),
                child: const Icon(Icons.delete_outline,
                    size: 18, color: _error),
              ),
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
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: _onSurfaceVariant.withOpacity(0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 4 – Detalles finales
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep4() {
    const dificultades = [
      {'label': 'Principiante', 'icon': Icons.egg_alt_outlined},
      {'label': 'Intermedio', 'icon': Icons.restaurant_outlined},
      {'label': 'Experto', 'icon': Icons.local_fire_department_outlined},
    ];

    return Column(
      children: [
        // Numbers grid
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? _primary.withOpacity(0.06)
                              : _surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? _primary : _outline.withOpacity(0.4),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              info['icon'] as IconData,
                              color:
                              selected ? _primary : _onSurfaceVariant.withOpacity(0.4),
                              size: 22,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              info['label'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: selected ? _onSurface : _onSurfaceVariant.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
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
        const SizedBox(height: 16),
        // Summary card
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.analytics_outlined, color: _primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Resumen de la receta',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 130,
                decoration: BoxDecoration(
                  color: _surfaceDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _outline.withOpacity(0.3)),
                ),
                child: const Center(
                  child: Icon(Icons.image_outlined,
                      color: Color(0xFFCBD5E1), size: 36),
                ),
              ),
              const SizedBox(height: 16),
              _summaryRow('Ingredientes', '${_ingredients.length} items'),
              _summaryRow('Pasos', '${_pasos.length} pasos'),
              _summaryRow('Dificultad',
                  ['Principiante', 'Intermedio', 'Experto'][_dificultad]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _primary.withOpacity(0.1)),
                ),
                child: Text(
                  '"${_nombreCtrl.text.isEmpty ? 'Tu receta sin título aún...' : _nombreCtrl.text}"',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: _onSurfaceVariant.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberGrid() {
    return Column(
      children: [
        Row(children: [
          Expanded(
              child: _numberField(
                  label: 'PORCIONES',
                  controller: _porcionesCtrl,
                  hint: '4')),
          const SizedBox(width: 12),
          Expanded(
              child: _numberField(
                  label: 'PESO POR PORCIÓN (G)',
                  controller: _pesoPorcionCtrl,
                  hint: '250')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _numberField(
                  label: 'TIEMPO PREP. (MIN)',
                  controller: _tiempoCtrl,
                  hint: '45',
                  suffixIcon: Icons.schedule)),
          const SizedBox(width: 12),
          Expanded(
              child: _numberField(
                  label: 'CALORÍAS EST. (KCAL)',
                  controller: _caloriasCtrl,
                  hint: '420')),
        ]),
      ],
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: _onSurfaceVariant.withOpacity(0.6),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: _onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: _onSurfaceVariant.withOpacity(0.3),
                fontWeight: FontWeight.w500),
            filled: true,
            fillColor: _surface,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _outline.withOpacity(0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon,
                color: _onSurfaceVariant.withOpacity(0.3), size: 18)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
          border: Border(
              bottom:
              BorderSide(color: Colors.black.withOpacity(0.05)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: _onSurfaceVariant.withOpacity(0.5),
                  letterSpacing: 1.2)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _onSurface)),
        ],
      ),
    );
  }

  // ─── Footer ─────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    final isLast = _step == 4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _surface.withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (_step > 1) setState(() => _step--);
              else Navigator.pop(context);
            },
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 12, color: _onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'VOLVER',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: _onSurfaceVariant.withOpacity(0.7),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (!isLast) {
                setState(() => _step++);
              } else {
                _snack('Borrador guardado ✓');
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Row(
                children: [
                  if (isLast)
                    const Icon(Icons.save_outlined,
                        color: Colors.white, size: 16),
                  if (isLast) const SizedBox(width: 8),
                  Text(
                    isLast ? 'GUARDAR BORRADOR' : 'SIGUIENTE PASO',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.8,
                    ),
                  ),
                  if (!isLast) const SizedBox(width: 8),
                  if (!isLast)
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared helpers ─────────────────────────────────────────────────────────
  Widget _card({
    required Widget child,
    EdgeInsetsGeometry? padding,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        color: _primary.withOpacity(0.7),
        letterSpacing: 1.8,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: _onSurface,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: _onSurfaceVariant.withOpacity(0.35),
            fontWeight: FontWeight.w400,
            fontSize: fontSize),
        filled: true,
        fillColor: _surfaceDim,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _searchField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: _onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: _onSurfaceVariant.withOpacity(0.35),
            fontWeight: FontWeight.w400),
        prefixIcon: Icon(Icons.search, color: _primary.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: _surfaceDim,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }
}