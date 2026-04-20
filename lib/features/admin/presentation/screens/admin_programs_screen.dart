import 'package:flutter/material.dart';
import 'package:sigetu/core/utils/responsive.dart';
import 'package:sigetu/core/widgets/app_toast.dart';
import 'package:sigetu/features/admin/data/admin_programs_api.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_async_state_view.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_dialog_action_buttons.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_page_container.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_page_action_button.dart';
import 'package:sigetu/features/shared/domain/academic_program.dart';

class AdminProgramsScreen extends StatefulWidget {
  const AdminProgramsScreen({super.key});

  @override
  State<AdminProgramsScreen> createState() => _AdminProgramsScreenState();
}

class _AdminProgramsScreenState extends State<AdminProgramsScreen> {
  final _api = AdminProgramsApi();

  bool _isLoading = true;
  String? _errorMessage;
  List<AcademicProgram> _programs = [];

  Future<void> _openCreateProgramDialog() async {
    final payload = await showDialog<_ProgramFormPayload>(
      context: context,
      builder: (_) => const _CreateProgramDialog(),
    );

    if (payload == null) {
      return;
    }

    try {
      final message = await _api.createProgram(
        codigo: payload.codigo,
        nombre: payload.nombre,
        descripcion: payload.descripcion,
        activo: payload.activo,
      );

      if (!mounted) return;
      await AppToast.showSuccess(
        context,
        message: message ?? 'Programa académico creado',
      );
      await _loadPrograms();
    } catch (error) {
      if (!mounted) return;
      await AppToast.showError(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _openEditProgramDialog(AcademicProgram program) async {
    final payload = await showDialog<_ProgramPatchPayload>(
      context: context,
      builder: (_) => _EditProgramDialog(program: program),
    );

    if (payload == null) {
      return;
    }

    try {
      final message = await _api.updateProgram(
        program.id,
        codigo: payload.codigo,
        nombre: payload.nombre,
        descripcion: payload.descripcion,
        activo: payload.activo,
      );

      if (!mounted) return;
      await AppToast.showSuccess(
        context,
        message: message ?? 'Programa académico actualizado',
      );
      await _loadPrograms();
    } catch (error) {
      if (!mounted) return;
      await AppToast.showError(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _deleteProgram(AcademicProgram program) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar programa académico'),
        content: Text('¿Deseas eliminar "${program.nombre}"?'),
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

    if (confirm != true) {
      return;
    }

    try {
      final message = await _api.deleteProgram(program.id);
      if (!mounted) return;

      await AppToast.showSuccess(
        context,
        message: message ?? 'Programa académico eliminado',
      );
      await _loadPrograms();
    } catch (error) {
      if (!mounted) return;
      await AppToast.showError(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final programs = await _api.fetchPrograms();
      if (!mounted) return;
      setState(() {
        _programs = programs;
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

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.horizontalPadding(context);

    return AdminPageContainer(
      title: 'Programas Académicos',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AdminPageActionButton(
            onPressed: _openCreateProgramDialog,
            icon: Icons.add,
            label: 'Agregar',
          ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadPrograms,
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const AdminLoadingView();
            }

            if (_errorMessage != null) {
              return AdminErrorView(
                message: _errorMessage!,
                onRetry: _loadPrograms,
              );
            }

            if (_programs.isEmpty) {
              return const AdminEmptyView(
                message: 'No hay programas académicos activos',
              );
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
              itemCount: _programs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final program = _programs[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: Text(program.nombre),
                    subtitle: Text(
                      (program.descripcion?.trim().isNotEmpty ?? false)
                          ? program.descripcion!
                          : 'Código: ${program.codigo}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openEditProgramDialog(program);
                        } else if (value == 'delete') {
                          _deleteProgram(program);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Eliminar'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProgramFormPayload {
  const _ProgramFormPayload({
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

class _ProgramPatchPayload {
  const _ProgramPatchPayload({
    this.codigo,
    this.nombre,
    this.descripcion,
    this.activo,
  });

  final String? codigo;
  final String? nombre;
  final String? descripcion;
  final bool? activo;
}

class _CreateProgramDialog extends StatefulWidget {
  const _CreateProgramDialog();

  @override
  State<_CreateProgramDialog> createState() => _CreateProgramDialogState();
}

class _CreateProgramDialogState extends State<_CreateProgramDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  bool _activo = true;

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
      _ProgramFormPayload(
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
      title: const Text('Agregar programa académico'),
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
                  hintText: 'Ej: 123abc',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2) {
                    return 'Mínimo 2 caracteres';
                  }
                  if (text.length > 50) {
                    return 'Máximo 50 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Ingenierías',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2) {
                    return 'Mínimo 2 caracteres';
                  }
                  if (text.length > 120) {
                    return 'Máximo 120 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length > 255) {
                    return 'Máximo 255 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: _activo,
                onChanged: (value) => setState(() => _activo = value),
                title: const Text('Activo'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AdminDialogActionButtons(
            confirmLabel: 'Guardar',
            onConfirm: _submit,
            cancelLabel: 'Cancelar',
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _EditProgramDialog extends StatefulWidget {
  const _EditProgramDialog({required this.program});

  final AcademicProgram program;

  @override
  State<_EditProgramDialog> createState() => _EditProgramDialogState();
}

class _EditProgramDialogState extends State<_EditProgramDialog> {
  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  final _formKey = GlobalKey<FormState>();
  late bool _activo;

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(text: widget.program.codigo);
    _nombreController = TextEditingController(text: widget.program.nombre);
    _descripcionController = TextEditingController(
      text: widget.program.descripcion ?? '',
    );
    _activo = widget.program.activo;
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

    final codigo = _codigoController.text.trim();
    final nombre = _nombreController.text.trim();
    final descripcion = _descripcionController.text.trim();

    final codigoChanged = codigo != widget.program.codigo;
    final nombreChanged = nombre != widget.program.nombre;
    final originalDesc = (widget.program.descripcion ?? '').trim();
    final descripcionChanged = descripcion != originalDesc;
    final activoChanged = _activo != widget.program.activo;

    // Detectamos cambios campo a campo para enviar un PATCH realmente parcial.

    if (!codigoChanged &&
        !nombreChanged &&
        !descripcionChanged &&
        !activoChanged) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop(
      _ProgramPatchPayload(
        codigo: codigoChanged ? codigo : null,
        nombre: nombreChanged ? nombre : null,
        descripcion: descripcionChanged ? descripcion : null,
        activo: activoChanged ? _activo : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Actualizar programa académico'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codigoController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Código'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2) {
                    return 'Mínimo 2 caracteres';
                  }
                  if (text.length > 50) {
                    return 'Máximo 50 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2) {
                    return 'Mínimo 2 caracteres';
                  }
                  if (text.length > 120) {
                    return 'Máximo 120 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length > 255) {
                    return 'Máximo 255 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: _activo,
                onChanged: (value) => setState(() => _activo = value),
                title: const Text('Activo'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AdminDialogActionButtons(
            confirmLabel: 'Actualizar',
            onConfirm: _submit,
            cancelLabel: 'Cancelar',
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}