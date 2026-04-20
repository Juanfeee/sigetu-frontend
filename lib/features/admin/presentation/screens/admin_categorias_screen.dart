import 'package:flutter/material.dart';
import 'package:sigetu/core/utils/responsive.dart';
import 'package:sigetu/core/widgets/app_toast.dart';
import 'package:sigetu/features/admin/data/admin_categorias_api.dart';
import 'package:sigetu/features/admin/presentation/screens/admin_contextos_screen.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_async_state_view.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_dialog_action_buttons.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_page_container.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_page_action_button.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_page_header.dart';
import 'package:sigetu/features/headquarters/domain/sede.dart';
import 'package:sigetu/features/headquarters/domain/sede_categoria.dart';

class AdminCategoriasScreen extends StatefulWidget {
  const AdminCategoriasScreen({super.key, required this.sede});

  final Sede sede;

  @override
  State<AdminCategoriasScreen> createState() => _AdminCategoriasScreenState();
}

class _AdminCategoriasScreenState extends State<AdminCategoriasScreen> {
  final _api = AdminCategoriasApi();

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
      final categorias = await _api.fetchCategoriasPorSede(widget.sede.id);
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

  Future<void> _openCreateCategoriaDialog() async {
    final payload = await showDialog<_CategoriaFormPayload>(
      context: context,
      builder: (_) => const _CategoriaFormDialog(
        title: 'Agregar categoría',
        confirmLabel: 'Guardar',
      ),
    );

    if (payload == null) return;

    try {
      final message = await _api.createCategoria(
        sedeId: widget.sede.id,
        codigo: payload.codigo,
        nombre: payload.nombre,
        descripcion: payload.descripcion,
        activo: payload.activo,
      );
      if (!mounted) return;
      await AppToast.showSuccess(
        context,
        message: message ?? 'Categoría creada',
      );
      await _loadCategorias();
    } catch (error) {
      if (!mounted) return;
      await AppToast.showError(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _openEditCategoriaDialog(SedeCategoria categoria) async {
    final payload = await showDialog<_CategoriaFormPayload>(
      context: context,
      builder: (_) => _CategoriaFormDialog(
        title: 'Editar categoría',
        confirmLabel: 'Actualizar',
        initialCategoria: categoria,
      ),
    );

    if (payload == null) return;

    try {
      final message = await _api.updateCategoria(
        categoria.id,
        codigo: payload.codigo,
        nombre: payload.nombre,
        descripcion: payload.descripcion,
        activo: payload.activo,
      );
      if (!mounted) return;
      await AppToast.showSuccess(
        context,
        message: message ?? 'Categoría actualizada',
      );
      await _loadCategorias();
    } catch (error) {
      if (!mounted) return;
      await AppToast.showError(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _deleteCategoria(SedeCategoria categoria) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Deseas eliminar "${categoria.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final message = await _api.deleteCategoria(categoria.id);
      if (!mounted) return;
      await AppToast.showSuccess(
        context,
        message: message ?? 'Categoría eliminada',
      );
      await _loadCategorias();
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
      title: 'Categorías · ${widget.sede.nombre}',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AdminPageActionButton(
            onPressed: _openCreateCategoriaDialog,
            icon: Icons.add,
            label: 'Agregar',
          ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadCategorias,
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const AdminLoadingView();
            }

            if (_errorMessage != null) {
              return AdminErrorView(
                message: _errorMessage!,
                onRetry: _loadCategorias,
              );
            }

            if (_categorias.isEmpty) {
              return const AdminEmptyView(
                message: 'No hay categorías creadas para esta sede',
              );
            }

            return ListView(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
              children: [
                AdminPageHeader(
                  title: 'Categorías · ${widget.sede.nombre}',
                  subtitle: 'Administra las categorías activas de esta sede',
                  icon: Icons.category_outlined,
                ),
                const SizedBox(height: 16),
                for (int index = 0; index < _categorias.length; index++) ...[
                  _CategoriaAdminCard(
                    categoria: _categorias[index],
                    sedeNombre: widget.sede.nombre,
                    onOpenContextos: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminContextosScreen(
                            categoria: _categorias[index],
                          ),
                        ),
                      );
                    },
                    onEdit: () => _openEditCategoriaDialog(_categorias[index]),
                    onDelete: () => _deleteCategoria(_categorias[index]),
                  ),
                  if (index != _categorias.length - 1)
                    const SizedBox(height: 14),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoriaAdminCard extends StatelessWidget {
  const _CategoriaAdminCard({
    required this.categoria,
    required this.sedeNombre,
    required this.onOpenContextos,
    required this.onEdit,
    required this.onDelete,
  });

  final SedeCategoria categoria;
  final String sedeNombre;
  final VoidCallback onOpenContextos;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface.withValues(alpha: 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenContextos,
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.workspaces_outline,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoria.nombre,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (categoria.descripcion?.trim().isNotEmpty ?? false)
                              ? categoria.descripcion!
                              : 'Sin descripción',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: categoria.activo
                          ? scheme.primaryContainer.withValues(alpha: 0.6)
                          : scheme.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      categoria.activo ? 'Activa' : 'Inactiva',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: categoria.activo
                            ? scheme.onPrimaryContainer
                            : scheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(sedeNombre)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.code_outlined,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Código: ${categoria.codigo}')),
                ],
              ),
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

class _CategoriaFormPayload {
  const _CategoriaFormPayload({
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.activo,
  });

  final String codigo;
  final String nombre;
  final String? descripcion;
  final bool activo;
}

class _CategoriaFormDialog extends StatefulWidget {
  const _CategoriaFormDialog({
    required this.title,
    required this.confirmLabel,
    this.initialCategoria,
  });

  final String title;
  final String confirmLabel;
  final SedeCategoria? initialCategoria;

  @override
  State<_CategoriaFormDialog> createState() => _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends State<_CategoriaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();

  bool _activo = true;

  @override
  void initState() {
    super.initState();
    final categoria = widget.initialCategoria;
    if (categoria != null) {
      _codigoController.text = categoria.codigo;
      _nombreController.text = categoria.nombre;
      _descripcionController.text = categoria.descripcion ?? '';
      _activo = categoria.activo;
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final descripcion = _descripcionController.text.trim();
    Navigator.of(context).pop(
      _CategoriaFormPayload(
        codigo: _codigoController.text.trim(),
        nombre: _nombreController.text.trim(),
        descripcion: descripcion.isEmpty ? null : descripcion,
        activo: _activo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codigoController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Código',
                  hintText: 'Ej: pagos_facturacion',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2) return 'Mínimo 2 caracteres';
                  if (text.length > 50) return 'Máximo 50 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Pagos y Facturación',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2) return 'Mínimo 2 caracteres';
                  if (text.length > 120) return 'Máximo 120 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Descripción breve de la categoría',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length > 255) return 'Máximo 255 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activa'),
                value: _activo,
                onChanged: (value) => setState(() => _activo = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AdminDialogActionButtons(
            confirmLabel: widget.confirmLabel,
            onConfirm: _submit,
            cancelLabel: 'Cancelar',
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
