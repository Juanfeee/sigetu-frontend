import 'package:flutter/material.dart';
import 'package:sigetu/core/utils/responsive.dart';
import 'package:sigetu/core/widgets/app_toast.dart';
import 'package:sigetu/features/admin/data/admin_contextos_api.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_async_state_view.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_dialog_action_buttons.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_page_container.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_page_action_button.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_page_header.dart';
import 'package:sigetu/features/headquarters/domain/categoria_contexto.dart';
import 'package:sigetu/features/headquarters/domain/sede_categoria.dart';

class AdminContextosScreen extends StatefulWidget {
  const AdminContextosScreen({super.key, required this.categoria});

  final SedeCategoria categoria;

  @override
  State<AdminContextosScreen> createState() => _AdminContextosScreenState();
}

class _AdminContextosScreenState extends State<AdminContextosScreen> {
  final _api = AdminContextosApi();

  bool _isLoading = true;
  String? _errorMessage;
  List<CategoriaContexto> _contextos = [];

  @override
  void initState() {
    super.initState();
    _loadContextos();
  }

  Future<void> _loadContextos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contextos = await _api.fetchContextosPorCategoria(widget.categoria.id);
      if (!mounted) return;
      setState(() => _contextos = contextos);
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

  Future<void> _openCreateContextoDialog() async {
    final payload = await showDialog<_ContextoFormPayload>(
      context: context,
      builder: (_) => const _ContextoFormDialog(
        title: 'Agregar contexto',
        confirmLabel: 'Guardar',
      ),
    );

    if (payload == null) return;

    try {
      final message = await _api.createContexto(
        categoriaId: widget.categoria.id,
        codigo: payload.codigo,
        nombre: payload.nombre,
        descripcion: payload.descripcion,
        activo: payload.activo,
      );
      if (!mounted) return;
      await AppToast.showSuccess(
        context,
        message: message ?? 'Contexto creado',
      );
      await _loadContextos();
    } catch (error) {
      if (!mounted) return;
      await AppToast.showError(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _openEditContextoDialog(CategoriaContexto contexto) async {
    final payload = await showDialog<_ContextoFormPayload>(
      context: context,
      builder: (_) => _ContextoFormDialog(
        title: 'Editar contexto',
        confirmLabel: 'Actualizar',
        initialContexto: contexto,
      ),
    );

    if (payload == null) return;

    try {
      final message = await _api.updateContexto(
        contexto.id,
        codigo: payload.codigo,
        nombre: payload.nombre,
        descripcion: payload.descripcion,
        activo: payload.activo,
      );
      if (!mounted) return;
      await AppToast.showSuccess(
        context,
        message: message ?? 'Contexto actualizado',
      );
      await _loadContextos();
    } catch (error) {
      if (!mounted) return;
      await AppToast.showError(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _deleteContexto(CategoriaContexto contexto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar contexto'),
        content: Text('¿Deseas eliminar "${contexto.nombre}"?'),
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
      final message = await _api.deleteContexto(contexto.id);
      if (!mounted) return;
      await AppToast.showSuccess(
        context,
        message: message ?? 'Contexto eliminado',
      );
      await _loadContextos();
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
      title: 'Contextos · ${widget.categoria.nombre}',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AdminPageActionButton(
            onPressed: _openCreateContextoDialog,
            icon: Icons.add,
            label: 'Agregar',
          ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadContextos,
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const AdminLoadingView();
            }

            if (_errorMessage != null) {
              return AdminErrorView(
                message: _errorMessage!,
                onRetry: _loadContextos,
              );
            }

            if (_contextos.isEmpty) {
              return const AdminEmptyView(
                message: 'No hay contextos creados para esta categoría',
              );
            }

            return ListView(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
              children: [
                AdminPageHeader(
                  title: 'Contextos · ${widget.categoria.nombre}',
                  subtitle: 'Gestiona los contextos asociados a esta categoría',
                  icon: Icons.topic_outlined,
                ),
                const SizedBox(height: 16),
                for (int index = 0; index < _contextos.length; index++) ...[
                  _ContextoAdminCard(
                    contexto: _contextos[index],
                    categoriaNombre: widget.categoria.nombre,
                    onEdit: () => _openEditContextoDialog(_contextos[index]),
                    onDelete: () => _deleteContexto(_contextos[index]),
                  ),
                  if (index != _contextos.length - 1)
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

class _ContextoAdminCard extends StatelessWidget {
  const _ContextoAdminCard({
    required this.contexto,
    required this.categoriaNombre,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoriaContexto contexto;
  final String categoriaNombre;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
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
                  Icons.redeem_outlined,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contexto.nombre,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (contexto.descripcion?.trim().isNotEmpty ?? false)
                          ? contexto.descripcion!
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
                  color: contexto.activo
                      ? scheme.primaryContainer.withValues(alpha: 0.6)
                      : scheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  contexto.activo ? 'Activa' : 'Inactiva',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: contexto.activo
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
                Icons.category_outlined,
                size: 18,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(categoriaNombre)),
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
              Expanded(child: Text('Código: ${contexto.codigo}')),
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
    );
  }
}

class _ContextoFormPayload {
  const _ContextoFormPayload({
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

class _ContextoFormDialog extends StatefulWidget {
  const _ContextoFormDialog({
    required this.title,
    required this.confirmLabel,
    this.initialContexto,
  });

  final String title;
  final String confirmLabel;
  final CategoriaContexto? initialContexto;

  @override
  State<_ContextoFormDialog> createState() => _ContextoFormDialogState();
}

class _ContextoFormDialogState extends State<_ContextoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();

  bool _activo = true;

  @override
  void initState() {
    super.initState();
    final contexto = widget.initialContexto;
    if (contexto != null) {
      _codigoController.text = contexto.codigo;
      _nombreController.text = contexto.nombre;
      _descripcionController.text = contexto.descripcion ?? '';
      _activo = contexto.activo;
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
      _ContextoFormPayload(
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
                  hintText: 'Ej: validacion_pagos',
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
                  hintText: 'Ej: Validación de Pagos',
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
                  hintText: 'Descripción breve del contexto',
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
                title: const Text('Activo'),
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
