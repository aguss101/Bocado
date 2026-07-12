import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_module/models/UsuarioLogged.dart';
import 'package:flutter_module/services/Instructions.dart';
import '../services/Receta.dart';
import '../utils/IdCodec.dart';
import '../theme/App.dart';
import '../theme/Notifier.dart';
import '../widgets/Common.dart';
import '../route_observer.dart';
import 'EditRecipe.dart';
import 'Profile.dart';
import '../models/RecipeComment.dart';

class RecipeDetailData {
  final String titulo;
  final String categoria;
  final String imageUrl;
  final double calorias;
  final String proteina;
  final String carbos;
  final String grasas;
  final String duracion;
  final String porciones;
  final List<IngredientItem> ingredientes;
  final List<PreparationStep> pasos;
  final String nombreAutor;
  final String? fotoAutor;
  final double? precioPorcion;
  final double calificacionPromedio;

  const RecipeDetailData({
    required this.titulo,
    required this.categoria,
    required this.imageUrl,
    required this.calorias,
    required this.proteina,
    required this.carbos,
    required this.grasas,
    required this.duracion,
    required this.porciones,
    required this.ingredientes,
    required this.pasos,
    this.nombreAutor = '',
    this.fotoAutor,
    this.precioPorcion,
    this.calificacionPromedio = 0.0,
  });

  factory RecipeDetailData.fromJson(
      Map<String, dynamic> json,
      double _prot,
      double _carb,
      double _gras,
      ) {
    double promedioExtraido = 0.0;
    if (json['estadisticas_receta'] != null && json['estadisticas_receta'] is Map) {
      promedioExtraido = (json['estadisticas_receta']['promedio_calificacion'] as num?)?.toDouble() ?? 0.0;
    } else if (json['promedio_calificacion'] != null) {
      promedioExtraido = (json['promedio_calificacion'] as num?)?.toDouble() ?? 0.0;
    }

    return RecipeDetailData(
      titulo: json['nombre'] ?? '',
      categoria: 'General',
      imageUrl: json['foto'] ?? '',
      calorias: (json['calorias_totales'] ?? 0).toDouble(),
      proteina: _prot.toStringAsFixed(1),
      carbos: _carb.toStringAsFixed(1),
      grasas: _gras.toStringAsFixed(1),
      duracion: _formatDuracion(json['tiempo_coccion']),
      porciones: '${json['porciones'] ?? 0} porciones',
      ingredientes: (json['recetas_alimentos'] as List? ?? [])
          .map((item) => IngredientItem.fromJson(item))
          .toList(),
      pasos: PreparationStep.parsearInstrucciones(json['instrucciones'] ?? ''),
      nombreAutor: (json['usuarios'] as Map<String, dynamic>?)?['usuario'] ?? 'Usuario',
      fotoAutor: (json['usuarios'] as Map<String, dynamic>?)?['foto'],
      precioPorcion: _calcularPrecioPorcion(json),
      calificacionPromedio: promedioExtraido,
    );
  }

  static String _formatDuracion(dynamic raw) {
    final min = (raw as num?)?.toInt() ?? 0;
    if (min <= 0) return 'N/A';
    return '$min min';
  }

  static double? _calcularPrecioPorcion(Map<String, dynamic> json) {
    final precio = (json['precio'] as num?)?.toDouble();
    final porciones = (json['porciones'] as num?)?.toInt() ?? 0;
    if (precio == null || porciones <= 0) return null;
    return precio / porciones;
  }
}

class IngredientItem {
  final String nombre;
  final String cantidad;
  final bool resaltado;

  const IngredientItem({
    required this.nombre,
    required this.cantidad,
    this.resaltado = false,
  });

  factory IngredientItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> alimento = json['alimentos'] ?? {};
    final int idMedida = json['id_medida'] is int
          ? json['id_medida'] as int
          : int.tryParse(json['id_medida']?.toString() ?? '') ?? 1;
    return IngredientItem(
      nombre: alimento['nombre'] ?? 'Ingrediente desconocido',
      cantidad: '${json['cantidad'] ?? 0}${unitForMedida(idMedida)}',
      resaltado: false,
    );
  }
}

class PreparationStep {
  final int numeroPaso;
  final String titulo;
  final String descripcion;
  final String? duracion;
  final List<String> imagenes;

  const PreparationStep({
    required this.numeroPaso,
    required this.titulo,
    required this.descripcion,
    this.duracion,
    this.imagenes = const [],
  });

  static List<PreparationStep> parsearInstrucciones(String cadena) {
    if (cadena.isEmpty) return [];

    List<String> fragmentos = cadena.split('|');
    List<PreparationStep> pasos = [];

    for (int i = 0; i < fragmentos.length; i++) {
      String pasoTrim = fragmentos[i].trim();

      if (pasoTrim.isNotEmpty) {
        pasos.add(
          PreparationStep(
            numeroPaso: i + 1,
            titulo: 'Paso ${i + 1}',
            descripcion: pasoTrim,
          ),
        );
      }
    }
    return pasos;
  }
}

class RecipeDetailScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final usuario_Logged user;
  final int idReceta;
  final double protFeed;
  final double carbFeed;
  final double grasFeed;
  final int? idAutor;
  final bool isLikedInicial;
  final bool isPreview;
  final RecipeDetailData? previewData;
  final List<Uint8List>? previewImageBytes;

  const RecipeDetailScreen({
    super.key,
    required this.themeNotifier,
    required this.user,
    required this.idReceta,
    required this.protFeed,
    required this.carbFeed,
    required this.grasFeed,
    this.idAutor,
    this.isLikedInicial = false,
    this.isPreview = false,
    this.previewData,
    this.previewImageBytes,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  BocadoColors get _c => BocadoColors.of(context);
  bool _isFavorite = false;
  bool _likeEnCurso = false;
  bool _isSaved = false;
  bool _saveEnCurso = false;
  bool _isLoading = true;
  bool _abriendoEditor = false;
  RecipeDetailData? _data;
  final PageController _pageController = PageController();
  final ValueNotifier<List<RecipeComment>> _comentariosNotifier = ValueNotifier([]);
  final ValueNotifier<double> _ratingNotifier = ValueNotifier(0.0);

  @override
  void dispose() {
    _comentariosNotifier.dispose();
    _ratingNotifier.dispose();
    super.dispose();
  }

  bool get _esPropia =>
      widget.idAutor != null && widget.idAutor == widget.user.id;

  void _irAlPerfilAutor() {
    if (widget.idAutor == null) return;
    pushOrReuse(
      context,
      'perfil/${widget.idAutor}',
          (_) => ProfileScreen(
        user: widget.user,
        themeNotifier: widget.themeNotifier,
        idUsuarioTarget: widget.idAutor,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isLikedInicial;
    if (widget.previewData != null) {
      _data = widget.previewData;
      _isLoading = false;
    } else {
      _traerDetalleDeLaReceta();
      _sincronizarEstadoLike();
      cargarComentarios(widget.idReceta);
    }
  }

  Future<void> _sincronizarEstadoLike() async {
    try {
      final tipos = await InteraccionesService.fetchMisInteracciones(
        widget.user.id,
        widget.idReceta,
      );
      if (!mounted) return;
      setState(() {
        if (!_likeEnCurso) _isFavorite = tipos.contains('like');
        if (!_saveEnCurso) _isSaved = tipos.contains('save');
      });
    } catch (_) {
    }
  }

  void _compartirReceta() {
    final slug = IdCodec.encodeReceta(widget.idReceta);
    final nombre = _data?.titulo ?? '';
    final intro = nombre.isNotEmpty
        ? '¡Mirá la receta $nombre en Bocado! 🍴'
        : '¡Mirá esta receta en Bocado! 🍴';
    SharePlus.instance.share(
      ShareParams(text: '$intro\nhttps://links.bocado.tech/receta/$slug'),
    );
  }

  Future<void> _handleLike() async {
    if (_likeEnCurso) return;
    final nuevoEstado = !_isFavorite;
    setState(() {
      _isFavorite = nuevoEstado;
      _likeEnCurso = true;
    });
    try {
      await InteraccionesService.toggleInteraction({
        'id_usuario': widget.user.id,
        'id_receta': widget.idReceta,
        'tipo': 'like',
        'is_adding': nuevoEstado,
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isFavorite = !nuevoEstado);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar el Like. Revisa tu conexión.')),
        );
      }
    } finally {
      if (mounted) setState(() => _likeEnCurso = false);
    }
  }

  Future<void> _handleSave() async {
    if (_saveEnCurso) return;
    final nuevoEstado = !_isSaved;
    setState(() {
      _isSaved = nuevoEstado;
      _saveEnCurso = true;
    });
    try {
      await InteraccionesService.toggleInteraction({
        'id_usuario': widget.user.id,
        'id_receta': widget.idReceta,
        'tipo': 'save',
        'is_adding': nuevoEstado,
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isSaved = !nuevoEstado);
        final esLimite = e is PlatformException && e.code == 'LIMITE_ALCANZADO';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(esLimite
              ? 'Llegaste al límite de 10 guardados. Hazte Premium para guardar sin límite.'
              : 'Error al guardar la receta. Revisa tu conexión.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _saveEnCurso = false);
    }
  }

  Future<void> _abrirEditor() async {
    if (_abriendoEditor) return;
    setState(() => _abriendoEditor = true);
    try {
      final data = await RecetaService.getRecetaParaEditar(widget.idReceta);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeEditorScreen(
            themeNotifier: widget.themeNotifier,
            user: widget.user,
            recetaExistente: data,
          ),
        ),
      );
      if (mounted) {
        setState(() => _isLoading = true);
        await _traerDetalleDeLaReceta();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el editor: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _abriendoEditor = false);
    }
  }

  Future<void> _traerDetalleDeLaReceta() async {
    try {
      final recetaJson = await RecetaService.getRecetaDetalle(widget.idReceta);
      if (mounted) {
        setState(() {
          _data = RecipeDetailData.fromJson(
            recetaJson,
            widget.protFeed,
            widget.carbFeed,
            widget.grasFeed,
          );
          _ratingNotifier.value = _data!.calificacionPromedio;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> cargarComentarios(int idReceta) async {
    try {
      String jsonString = await InteraccionesService.fetchComentarios(idReceta, widget.user.id);
      List<dynamic> jsonList = jsonDecode(jsonString);

      List<RecipeComment> comentariosPlanos = jsonList
          .map((j) => RecipeComment.fromJson(j))
          .toList();

      Map<int, RecipeComment> mapaComentarios = {};
      List<RecipeComment> comentariosRaiz = [];

      for (var c in comentariosPlanos) {
        mapaComentarios[c.idComentario] = c;
      }

      for (var c in comentariosPlanos) {
        final padre = c.idComentarioPadre != null
            ? mapaComentarios[c.idComentarioPadre]
            : null;
        if (padre != null) {
          padre.respuestas.add(c);
        } else {
          comentariosRaiz.add(c);
        }
      }

      final premium = comentariosRaiz.where((c) => c.esPremium).toList();
      final normales = comentariosRaiz.where((c) => !c.esPremium).toList();
      comentariosRaiz = [...premium, ...normales];

      for (final c in comentariosRaiz) {
        if (c.esPremium) {
          c.resaltar = true;
        }
      }

      if (mounted) {
        _comentariosNotifier.value = comentariosRaiz;
      }
    } catch (e) {
      print("Error cargando comentarios: $e");
    }
  }

  Future<void> _mostrarDialogoComentario(
      BuildContext context, {
        int? idPadre,
      }) async {
    final TextEditingController _controlador = TextEditingController();
    double _calificacion = 0;
    final yaComento = _comentariosNotifier.value.any((c) => c.idUsuario == widget.user.id && c.idComentarioPadre == null);
    final bool mostrarEstrellas = idPadre == null && !yaComento;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                idPadre == null ? 'Dejar un comentario' : 'Responder comentario',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (mostrarEstrellas) ...[
                    const Text('Califica esta receta:'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _calificacion ? Icons.star : Icons.star_border,
                            color: _c.rating,
                            size: 32,
                          ),
                          onPressed: () {
                            setState(() {
                              _calificacion = index + 1.0;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _controlador,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: idPadre == null
                          ? '¿Qué te pareció la receta?'
                          : 'Escribe tu respuesta...',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final texto = _controlador.text.trim();
                    if (texto.isNotEmpty || (mostrarEstrellas && _calificacion > 0)) {
                      Navigator.pop(context);
                      await _enviarComentarioADB(
                        texto,
                        idPadre: idPadre,
                        calificacion: _calificacion > 0 ? _calificacion : null,
                      );
                    }
                  },
                  child: const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _enviarComentarioADB(String texto, {int? idPadre, double? calificacion}) async {
    try {
      final Map<String, dynamic> datos = {
        'id_receta': widget.idReceta,
        'id_usuario': widget.user.id,
        'comentario': texto.isEmpty ? null : texto,
        'id_comentario_padre': idPadre,
        'calificacion': calificacion,
      };

      await InteraccionesService.enviarComentario(datos);
      await cargarComentarios(widget.idReceta);
      await _traerDetalleDeLaReceta();
    } catch (e) {
      print("Error publicando: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al publicar el comentario.'),
            backgroundColor: _c.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _abrirComentarios(
      BuildContext context,
      Color surface,
      Color outline,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Comentarios',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ValueListenableBuilder<List<RecipeComment>>(
                      valueListenable: _comentariosNotifier,
                      builder: (context, comentarios, child) {
                        return ListView.builder(
                          controller: controller,
                          itemCount: comentarios.length,
                          itemBuilder: (context, index) {
                            return _CommentCard(
                              comment: comentarios[index],
                              surface: surface,
                              outline: outline,
                              onReply: (idPadre) => _mostrarDialogoComentario(context, idPadre: idPadre),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = BocadoColors.of(context);
    final isDark = c.isDark;
    final surface = c.surfaceContainer;
    final outline = c.border;
    final List<dynamic> listaImagenes = widget.isPreview
        ? [
      ...(_data?.imageUrl
          .split('|')
          .where((url) => url.trim().isNotEmpty)
          .toList() ?? []),
      ...(widget.previewImageBytes ?? []),
    ]
        : (_data?.imageUrl
        .split('|')
        .where((url) => url.trim().isNotEmpty)
        .toList() ?? []);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(
          child: CircularProgressIndicator(color: c.primary),
        ),
      );
    }

    if (_data == null) {
      return Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: c.error,
              ),
              const SizedBox(height: 16),
              const Text(
                "¡Ups! Error al cargar la receta",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Volver"),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: widget.isPreview
          ? AppBar(
        title: Text("VISTA PREVIA", style: TextStyle(fontSize: 16, color: c.text, fontWeight: FontWeight.bold)),
        backgroundColor: c.bg.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.close, color: c.muted), onPressed: () => Navigator.pop(context)),
      )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: c.bg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_esPropia)
                IconButton(
                  tooltip: 'Editar receta',
                  onPressed: _abriendoEditor ? null : _abrirEditor,
                  icon: _abriendoEditor
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.edit_outlined, color: Colors.white),
                ),
              if (_esPropia)
                IconButton(
                  tooltip: 'Eliminar receta',
                  onPressed: () async {
                    final ok = await mostrarDialogoEliminarReceta(
                      context,
                      idReceta: widget.idReceta,
                      idUsuario: widget.user.id,
                    );
                    if (ok && mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                ),
              IconButton(
                tooltip: 'Compartir receta',
                onPressed: _compartirReceta,
                icon: const Icon(Icons.share_outlined, color: Colors.white),
              ),
              ThemeToggleButton(themeNotifier: widget.themeNotifier),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  listaImagenes.isNotEmpty
                      ? PageView(
                    controller: _pageController,
                    children: listaImagenes.map((item) {
                      if (item is Uint8List) {
                        return GestureDetector(
                          onLongPress: () => showFullscreenImage(context, bytes: item),
                          child: Image.memory(item, fit: BoxFit.cover),
                        );
                      } else if (item is String && item.startsWith('http')) {
                        return GestureDetector(
                          onLongPress: () => showFullscreenImage(context, url: item.trim()),
                          child: BocadoNetworkImage(
                            url: item.trim(),
                            errorWidget: Container(
                              color: c.surfaceContainer,
                              child: Icon(Icons.restaurant_menu, size: 64, color: c.primary),
                            ),
                          ),
                        );
                      } else {
                        return Container(
                          color: c.surfaceContainer,
                          child: Icon(Icons.restaurant_menu, size: 64, color: c.primary),
                        );
                      }
                    }).toList(),
                  )
                      : Container(
                    color: c.surfaceContainer,
                    child: Icon(Icons.restaurant_menu, size: 64, color: c.primary),
                  ),

                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 64,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: c.primary.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _data!.categoria.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            if (_data!.calificacionPromedio > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: c.rating.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      _data!.calificacionPromedio.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _data!.titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        if (!widget.isPreview) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _irAlPerfilAutor,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.white24,
                                  backgroundImage: (_data!.fotoAutor != null &&
                                      _data!.fotoAutor!.isNotEmpty)
                                      ? bocadoImageProvider(_data!.fotoAutor!)
                                      : null,
                                  child: (_data!.fotoAutor == null ||
                                      _data!.fotoAutor!.isEmpty)
                                      ? const Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _data!.nombreAutor,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if(!widget.isPreview)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _handleLike,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: _isFavorite ? c.like : Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _handleSave,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Icon(
                                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                                color: _isSaved ? c.primary : Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (listaImagenes.length > 1)
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _QuickInfo(
                        icon: Icons.schedule_outlined,
                        label: _data!.duracion,
                      ),
                      _QuickInfo(
                        icon: Icons.restaurant_outlined,
                        label: _data!.porciones,
                      ),
                      ValueListenableBuilder<double>(
                        valueListenable: _ratingNotifier,
                        builder: (context, promedio, child) {
                          if (promedio == 0) return const SizedBox.shrink();
                          return _QuickInfo(
                            icon: Icons.star,
                            label: promedio.toStringAsFixed(1),
                            iconColor: c.rating,
                            textColor: c.rating,
                          );
                        },
                      ),
                      if (_data!.precioPorcion != null)
                        _QuickInfo(
                          icon: Icons.attach_money,
                          label: '\$${_data!.precioPorcion!.toStringAsFixed(2)} / porción',
                          iconColor: c.primary,
                          textColor: c.primary,
                          fontSize: 15,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Información Nutricional'),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.65,
                    children: [
                      _NutriCard(
                        label: 'Calorías',
                        value: '${_data!.calorias.toInt()}',
                        sub: 'por porción',
                        surface: surface,
                        outline: outline,
                      ),
                      _NutriCard(
                        label: 'Proteína',
                        value: _data!.proteina,
                        sub: 'alta calidad',
                        surface: surface,
                        outline: outline,
                      ),
                      _NutriCard(
                        label: 'Carbohidratos',
                        value: _data!.carbos,
                        sub: 'complejos',
                        surface: surface,
                        outline: outline,
                      ),
                      _NutriCard(
                        label: 'Grasas',
                        value: _data!.grasas,
                        sub: 'totales',
                        surface: surface,
                        outline: outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _SectionTitle('Ingredientes'),
                  const SizedBox(height: 12),
                  ..._data!.ingredientes.map(
                        (i) => _IngredientRow(item: i, outline: outline),
                  ),
                  const SizedBox(height: 28),
                  const _SectionTitle('Preparación'),
                  const SizedBox(height: 16),
                  ..._data!.pasos.asMap().entries.map((entry) {
                    final isLast = entry.key == _data!.pasos.length - 1;
                    return _StepCard(
                      step: entry.value,
                      isLast: isLast,
                      outline: outline,
                      surface: surface,
                    );
                  }),
                  const SizedBox(height: 40),
                  if(!widget.isPreview) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionTitle('Comentarios'),
                        TextButton(
                          onPressed: () => _abrirComentarios(
                            context,
                            surface,
                            outline,
                          ),
                          child: Text(
                            'VER TODOS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: c.primary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  ValueListenableBuilder<List<RecipeComment>>(
                    valueListenable: _comentariosNotifier,
                    builder: (context, comentarios, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (comentarios.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('Sé el primero en dejar un comentario.'),
                            )
                          else
                            ...comentarios.take(2).map(
                                  (c) => _CommentCard(
                                comment: c,
                                surface: surface,
                                outline: outline,
                                onReply: (idPadre) => _mostrarDialogoComentario(context, idPadre: idPadre),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _mostrarDialogoComentario(context),
                      icon: const Icon(Icons.add_comment_outlined, size: 18),
                      label: const Text('Dejar un comentario'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: outline.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
  }
}

class _QuickInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? textColor;
  final double fontSize;

  const _QuickInfo({
    required this.icon,
    required this.label,
    this.iconColor,
    this.textColor,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final c = BocadoColors.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor ?? c.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: textColor),
        ),
      ],
    );
  }
}

class _NutriCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color surface;
  final Color outline;

  const _NutriCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.surface,
    required this.outline,
  });

  @override
  Widget build(BuildContext context) {
    final c = BocadoColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: c.primary,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final IngredientItem item;
  final Color outline;

  const _IngredientRow({required this.item, required this.outline});

  @override
  Widget build(BuildContext context) {
    final c = BocadoColors.of(context);
    final highlighted = item.resaltado;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: highlighted
            ? c.primary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? c.primary.withValues(alpha: 0.3)
              : outline.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          highlighted
              ? Icon(
            Icons.check_circle,
            color: c.primary,
            size: 16,
          )
              : Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: c.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.nombre,
              style: TextStyle(
                color: highlighted
                    ? c.primary.withValues(alpha: 0.9)
                    : null,
                fontWeight: highlighted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            item.cantidad,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: highlighted
                  ? c.primary
                  : Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final PreparationStep step;
  final bool isLast;
  final Color outline;
  final Color surface;

  const _StepCard({
    required this.step,
    required this.isLast,
    required this.outline,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final c = BocadoColors.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: step.numeroPaso == 1 ? c.primary : outline,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${step.numeroPaso}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: step.numeroPaso == 1
                            ? c.primary
                            : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: outline.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.descripcion,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (step.duracion != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: outline.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: c.primary,
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DURACIÓN',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  step.duracion!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (step.imagenes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: step.imagenes.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BocadoNetworkImage(
                              url: step.imagenes[i],
                              width: 160,
                              height: 100,
                              memCacheWidth: 320,
                              errorWidget: Container(
                                width: 160,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.image_outlined,
                                  color: c.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final RecipeComment comment;
  final Color surface;
  final Color outline;
  final Function(int) onReply;
  final bool isReply;

  const _CommentCard({
    required this.comment,
    required this.surface,
    required this.outline,
    required this.onReply,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = BocadoColors.of(context);
    final double valorCalificacion = comment.calificacion ?? 0.0;
    final int estrellasEnteras = valorCalificacion.floor();

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(
            bottom: isReply ? 8 : 12,
            left: isReply ? 32 : 0,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isReply
                ? Colors.transparent
                : (comment.resaltar
                ? c.rating.withValues(alpha: 0.08)
                : surface.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(16),
            border: isReply
                ? null
                : Border.all(
              color: comment.resaltar
                  ? c.rating
                  : outline.withValues(alpha: 0.3),
              width: comment.resaltar ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isReply ? 14 : 18,
                backgroundImage: comment.avatarUrl.isNotEmpty
                    ? bocadoImageProvider(comment.avatarUrl)
                    : null,
                backgroundColor: outline,
                child: comment.avatarUrl.isEmpty
                    ? Icon(Icons.person, size: isReply ? 16 : 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  comment.nombreUsuario,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: isReply ? 13 : 14,
                                  ),
                                ),
                              ),
                              if (comment.esPremium) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.star,
                                    color: c.premium, size: 13),
                              ],
                            ],
                          ),
                        ),
                        if (comment.fechaComentario != null)
                          Text(
                            "${comment.fechaComentario!.day}/${comment.fechaComentario!.month}/${comment.fechaComentario!.year}",
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (comment.calificacion != null && !isReply)
                      Row(
                        children: List.generate(5, (index) {
                          IconData icono;
                          if (index < estrellasEnteras) {
                            icono = Icons.star;
                          } else if (index == estrellasEnteras && (valorCalificacion - estrellasEnteras) >= 0.5) {
                            icono = Icons.star_half;
                          } else {
                            icono = Icons.star_border;
                          }
                          return Icon(
                            icono,
                            size: 14,
                            color: c.rating,
                          );
                        }),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      comment.comentario,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!isReply)
                      InkWell(
                        onTap: () => onReply(comment.idComentario),
                        child: Text(
                          "Responder",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (comment.respuestas.isNotEmpty)
          ...comment.respuestas.map(
                (respuesta) => _CommentCard(
              comment: respuesta,
              surface: surface,
              outline: outline,
              onReply: onReply,
              isReply: true,
            ),
          ),
      ],
    );
  }
}