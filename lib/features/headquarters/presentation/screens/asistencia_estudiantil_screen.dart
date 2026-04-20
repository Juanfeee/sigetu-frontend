import 'package:flutter/material.dart';
import 'package:sigetu/features/headquarters/data/sede_categorias_api.dart';
import 'package:sigetu/features/headquarters/domain/sede_categoria.dart';
import 'package:sigetu/features/headquarters/presentation/screens/agendar_cita_screen.dart';
import '../widgets/sede_option_card.dart';

class AsistenciaEstudiantilScreen extends StatefulWidget {
  const AsistenciaEstudiantilScreen({
    super.key,
    required this.sedeId,
    required this.sedeCodigo,
    required this.sedeNombre,
  });

  final int sedeId;
  final String sedeCodigo;
  final String sedeNombre;

  @override
  State<AsistenciaEstudiantilScreen> createState() =>
      _AsistenciaEstudiantilScreenState();
}

class _AsistenciaEstudiantilScreenState extends State<AsistenciaEstudiantilScreen> {
  final _categoriasApi = SedeCategoriasApi();
  bool _isLoading = true;
  String? _errorMessage;
  List<SedeCategoria> _categorias = [];

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  Future<void> _loadCategorias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categorias = await _categoriasApi.fetchCategoriasActivasPorSede(
        widget.sedeId,
      );
      if (!mounted) return;
      setState(() => _categorias = categorias);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sedeNombre)),
      body: RefreshIndicator(
        onRefresh: _loadCategorias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              if (_isLoading) ...[
                const SizedBox(height: 60),
                const Center(child: CircularProgressIndicator()),
              ] else if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadCategorias,
                  child: const Text('Reintentar'),
                ),
              ] else if (_categorias.isEmpty) ...[
                const Text('No hay categorías activas para esta sede.'),
              ] else ...[
                for (final categoria in _categorias)
                  SedeOptionCard(
                    title: categoria.nombre,
                    subtitle:
                        (categoria.descripcion?.trim().isNotEmpty ?? false)
                        ? categoria.descripcion!
                        : 'Selecciona para continuar',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AgendarCitaScreen(
                            categoriaId: categoria.id,
                            categoria: categoria.codigo,
                            categoriaNombre: categoria.nombre,
                            sedeCodigo: widget.sedeCodigo,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
