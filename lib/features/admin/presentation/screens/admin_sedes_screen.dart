import 'package:flutter/material.dart';
import 'package:sigetu/core/utils/responsive.dart';
import 'package:sigetu/core/widgets/app_toast.dart';
import 'package:sigetu/features/admin/data/admin_sedes_api.dart';
import 'package:sigetu/features/admin/presentation/screens/admin_categorias_screen.dart';
import 'package:sigetu/features/admin/presentation/screens/admin_sede_create_screen.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_async_state_view.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_dialog_action_buttons.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_page_container.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_page_action_button.dart';
import 'package:sigetu/features/headquarters/domain/sede.dart';

class AdminSedesScreen extends StatefulWidget {
  const AdminSedesScreen({super.key});

  @override
  State<AdminSedesScreen> createState() => _AdminSedesScreenState();
}

class _AdminSedesScreenState extends State<AdminSedesScreen> {
  final _api = AdminSedesApi();

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
      final sedes = await _api.fetchSedes();
      if (!mounted) return;
      setState(() {
        _sedes = sedes;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openCreateSedeDialog() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AdminSedeCreateScreen(),
      ),
    );

    if (created == true && mounted) {
      await _loadSedes();
    }
  }

  Future<void> _openEditSedeDialog(Sede sede) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminSedeCreateScreen(initialSede: sede),
      ),
    );

    if (updated == true && mounted) {
      await _loadSedes();
    }
  }

  Future<void> _deleteSede(Sede sede) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar sede'),
        content: Text('¿Deseas eliminar "${sede.nombre}"?'),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AdminDialogActionButtons(
              confirmLabel: 'Eliminar',
              onConfirm: () => Navigator.of(dialogContext).pop(true),
              cancelLabel: 'Cancelar',
              onCancel: () => Navigator.of(dialogContext).pop(false),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    try {
      final message = await _api.deleteSede(sede.id);

      if (!mounted) return;
      await AppToast.showSuccess(
        context,
        message: message ?? 'Sede eliminada',
      );
      await _loadSedes();
    } catch (error) {
      if (!mounted) return;
      await AppToast.showError(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.horizontalPadding(context);

    return AdminPageContainer(
      title: 'Sedes',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AdminPageActionButton(
            onPressed: _openCreateSedeDialog,
            icon: Icons.add,
            label: 'Agregar',
          ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadSedes,
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const AdminLoadingView();
            }

            if (_errorMessage != null) {
              return AdminErrorView(
                message: _errorMessage!,
                onRetry: _loadSedes,
              );
            }

            if (_sedes.isEmpty) {
              return const AdminEmptyView(
                message: 'No hay sedes creadas',
              );
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
              itemCount: _sedes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final sede = _sedes[index];
                return _SedeAdminCard(
                  sede: sede,
                  onOpenCategories: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminCategoriasScreen(sede: sede),
                      ),
                    );
                  },
                  onEdit: () => _openEditSedeDialog(sede),
                  onDelete: () => _deleteSede(sede),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SedeAdminCard extends StatelessWidget {
  const _SedeAdminCard({
    required this.sede,
    required this.onOpenCategories,
    required this.onEdit,
    required this.onDelete,
  });

  final Sede sede;
  final VoidCallback onOpenCategories;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = sede.filtrarCitasPorPrograma
      ? 'Filtra citas por programa'
      : 'Sin filtro de programa';

    return Material(
      color: scheme.surface.withValues(alpha: 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenCategories,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sede.nombre,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: sede.activo
                      ? scheme.primaryContainer.withValues(alpha: 0.6)
                      : scheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  sede.activo ? 'Activa' : 'Inactiva',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: sede.activo
                        ? scheme.onPrimaryContainer
                        : scheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (sede.ubicacion?.trim().isNotEmpty ?? false)
                      ? sede.ubicacion!
                      : 'Sin ubicación registrada',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.public_outlined,
                size: 18,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sede.esPublica
                      ? 'Visible para invitados'
                      : 'Visible solo para registrados',
                ),
              ),
            ],
          ),
          if (sede.descripcion?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              sede.descripcion!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                        side: BorderSide(
                          color: scheme.error.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

