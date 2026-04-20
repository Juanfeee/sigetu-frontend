import 'package:flutter/material.dart';
import 'package:sigetu/core/auth/auth_session.dart';
import 'package:sigetu/core/utils/responsive.dart';
import 'package:sigetu/core/widgets/section_header.dart';
import 'package:sigetu/features/headquarters/data/sedes_api.dart';
import 'package:sigetu/features/headquarters/domain/sede.dart';
import 'package:sigetu/features/headquarters/presentation/screens/asistencia_estudiantil_screen.dart';
import 'package:sigetu/features/student_dashboard/presentation/widgets/dashboard_card.dart';

class SeleccionarSedeScreen extends StatefulWidget {
  const SeleccionarSedeScreen({super.key});

  @override
  State<SeleccionarSedeScreen> createState() => _SeleccionarSedeScreenState();
}

class _SeleccionarSedeScreenState extends State<SeleccionarSedeScreen> {
  final _sedesApi = SedesApi();

  bool _isLoading = true;
  String? _errorMessage;
  List<Sede> _sedes = [];

  @override
  void initState() {
    super.initState();
    _loadSedes();
  }

  Future<void> _loadSedes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sedes = await _sedesApi.fetchSedesActivas();
      if (!mounted) return;
      setState(() => _sedes = sedes);
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

  bool _guestCanAccess(Sede sede) => sede.esPublica;

  Future<void> _openSede(Sede sede) async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AsistenciaEstudiantilScreen(
          sedeId: sede.id,
          sedeCodigo: sede.codigo,
          sedeNombre: sede.nombre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.horizontalPadding(context);
    final isWide = !Responsive.isMobile(context);
    final isGuest = AuthSession.isGuest;

    List<Widget> cards = _sedes.map((sede) {
      final locked = isGuest && !_guestCanAccess(sede);
      if (locked) {
        return _LockedCard(
          title: sede.nombre,
          subtitle: 'Disponible solo para usuarios registrados',
        );
      }

      return DashboardCard(
        title: sede.nombre,
        subtitle: (sede.descripcion?.trim().isNotEmpty ?? false)
            ? sede.descripcion!
            : (sede.ubicacion?.trim().isNotEmpty ?? false)
            ? sede.ubicacion!
            : 'Selecciona para continuar',
        imagePath: 'assets/images/asistencia_estudiantil.png',
        onTap: () => _openSede(sede),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar sede')),
      body: RefreshIndicator(
        onRefresh: _loadSedes,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
              children: [
                const SectionHeader(
                  title: 'Selecciona la sede',
                  subtitle: 'Elige la ubicación donde deseas solicitar tu turno',
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 60),
                  const Center(child: CircularProgressIndicator()),
                ] else if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadSedes,
                    child: const Text('Reintentar'),
                  ),
                ] else if (cards.isEmpty) ...[
                  const SizedBox(height: 40),
                  const Text('No hay sedes activas disponibles.'),
                ] else if (isWide) ...[
                  for (int i = 0; i < cards.length; i += 3)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cards[i]),
                          if (i + 1 < cards.length) ...[
                            const SizedBox(width: 16),
                            Expanded(child: cards[i + 1]),
                          ] else
                            const Spacer(),
                          if (i + 2 < cards.length) ...[
                            const SizedBox(width: 16),
                            Expanded(child: cards[i + 2]),
                          ] else
                            const Spacer(),
                        ],
                      ),
                    ),
                ] else ...[
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: 16),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta bloqueada para modo invitado
class _LockedCard extends StatelessWidget {
  const _LockedCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: 0.45,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.lock_outline, size: 18, color: scheme.onSurface),
          ],
        ),
      ),
    );
  }
}
