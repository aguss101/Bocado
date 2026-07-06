import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/Notifier.dart';
import '../theme/App.dart';
import '../models/UsuarioLogged.dart';
import '../models/RecetaFeed.dart';
import '../widgets/Common.dart';
import '../services/Receta.dart';

class SearchScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final usuario_Logged user;

  const SearchScreen({
    super.key,
    required this.themeNotifier,
    required this.user,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  bool _estaCargando = false;
  String _query = '';
  List<RecetaFeed> _resultados = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      _query = query;
    });

    if (query.trim().isEmpty) {
      setState(() {
        _resultados.clear();
        _estaCargando = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _realizarBusqueda(query);
    });
  }

  Future<void> _realizarBusqueda(String query) async {
    setState(() => _estaCargando = true);

    try {
      await Future.delayed(const Duration(seconds: 1));
      final resultadosAPI = await RecetaService.buscarRecetas(query);

      if (!mounted) return;
      setState(() {
        _resultados = resultadosAPI;
        _estaCargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _estaCargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al realizar la búsqueda.')),
      );
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BocadoColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Buscar', style: TextStyle(color: c.text, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(BocadoRadius.full ?? 30.0),
                border: Border.all(color: c.border),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                style: TextStyle(color: c.text),
                decoration: InputDecoration(
                  hintText: 'Buscar recetas, ingredientes...',
                  hintStyle: TextStyle(color: c.muted),
                  prefixIcon: Icon(Icons.search, color: c.muted),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: c.muted),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildContent(c),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(dynamic c) {
    if (_estaCargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_query.isEmpty) {
      return _buildEstadoInicial(c);
    }

    if (_resultados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: c.muted),
            const SizedBox(height: 16),
            Text(
              'No encontramos resultados para "$_query"',
              style: TextStyle(color: c.text, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba con otros ingredientes o términos',
              style: TextStyle(color: c.muted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _resultados.length,
      itemBuilder: (context, index) {
        final receta = _resultados[index];
        return _ResultCard(receta: receta, c: c);
      },
    );
  }

  Widget _buildEstadoInicial(dynamic c) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sugerencias',
            style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              _buildSugerenciaChip('Pollo', c),
              _buildSugerenciaChip('Desayunos', c),
              _buildSugerenciaChip('Alto en proteína', c),
              _buildSugerenciaChip('Sin TACC', c),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSugerenciaChip(String texto, dynamic c) {
    return ActionChip(
      backgroundColor: AppTheme.primary.withOpacity(0.1),
      side: BorderSide.none,
      label: Text(texto, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
      onPressed: () {
        _searchController.text = texto;
        _onSearchChanged(texto);
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  final RecetaFeed receta;
  final dynamic c;

  const _ResultCard({required this.receta, required this.c});

  @override
  Widget build(BuildContext context) {
    final String fotoUrl = receta.foto?.split('|')[0] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: fotoUrl.isNotEmpty
              ? Image.network(fotoUrl, width: 60, height: 60, fit: BoxFit.cover)
              : Container(width: 60, height: 60, color: Colors.grey[300]),
        ),
        title: Text(
          receta.nombre,
          style: TextStyle(color: c.text, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${receta.caloriasTotales.toInt()} kcal • ${receta.proteinasTotales}g prot',
          style: TextStyle(color: c.muted, fontSize: 12),
        ),
        onTap: () {},
      ),
    );
  }
}