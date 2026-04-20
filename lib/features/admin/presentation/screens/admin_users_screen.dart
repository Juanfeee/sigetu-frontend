import 'package:flutter/material.dart';
import 'package:sigetu/core/utils/responsive.dart';
import 'package:sigetu/core/widgets/app_toast.dart';
import 'package:sigetu/features/admin/data/admin_users_api.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_async_state_view.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_dialog_action_buttons.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_page_action_button.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_page_container.dart';
import 'package:sigetu/features/shared/domain/academic_program.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _api = AdminUsersApi();

  bool _isLoading = true;
  String? _errorMessage;
  List<AdminUserItem> _users = [];
  List<AcademicProgram> _programs = [];
  List<AdminRoleOption> _roles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _api.fetchUsers();
      final programs = await _api.fetchPrograms();
      final roles = await _api.fetchRoles();

      if (!mounted) return;
      setState(() {
        _users = users;
        _programs = programs;
        _roles = roles;
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

  Future<void> _openCreateUserDialog() async {
    if (_programs.isEmpty) {
      await AppToast.showError(
        context,
        message: 'No hay programas académicos disponibles.',
      );
      return;
    }
    if (_roles.isEmpty) {
      await AppToast.showError(
        context,
        message: 'No hay roles disponibles.',
      );
      return;
    }

    final payload = await showDialog<_CreateUserPayload>(
      context: context,
      builder: (_) => _CreateUserDialog(
        programs: _programs,
        roles: _roles,
      ),
    );

    if (payload == null) return;

    try {
      final message = await _api.createUser(
        email: payload.email,
        fullName: payload.fullName,
        password: payload.password,
        programaAcademicoId: payload.programaAcademicoId,
        roleId: payload.roleId,
        isActive: payload.isActive,
      );

      if (!mounted) return;
      await AppToast.showSuccess(
        context,
        message: message ?? 'Usuario creado correctamente',
      );
      await _loadData();
    } catch (error) {
      if (!mounted) return;
      await AppToast.showError(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _openEditUserDialog(AdminUserItem user) async {
    if (_programs.isEmpty) {
      await AppToast.showError(
        context,
        message: 'No hay programas académicos disponibles.',
      );
      return;
    }
    if (_roles.isEmpty) {
      await AppToast.showError(
        context,
        message: 'No hay roles disponibles.',
      );
      return;
    }

    try {
      final latest = await _api.fetchUserById(user.id);
      if (!mounted) return;

      final payload = await showDialog<_EditUserPayload>(
        context: context,
        builder: (_) => _EditUserDialog(
          user: latest,
          programs: _programs,
          roles: _roles,
        ),
      );

      if (payload == null) return;

      final message = await _api.updateUser(
        user.id,
        fullName: payload.fullName,
        programaAcademicoId: payload.programaAcademicoId,
        roleId: payload.roleId,
        isActive: payload.isActive,
      );

      if (!mounted) return;
      await AppToast.showSuccess(
        context,
        message: message ?? 'Usuario actualizado correctamente',
      );
      await _loadData();
    } catch (error) {
      if (!mounted) return;
      await AppToast.showError(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _deleteUser(AdminUserItem user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Deseas eliminar a "${user.fullName}"?'),
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

    if (confirm != true) return;

    try {
      final message = await _api.deleteUser(user.id);
      if (!mounted) return;
      await AppToast.showSuccess(
        context,
        message: message ?? 'Usuario eliminado correctamente',
      );
      await _loadData();
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
      title: 'Usuarios',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AdminPageActionButton(
            onPressed: _openCreateUserDialog,
            icon: Icons.person_add_alt_1,
            label: 'Agregar',
          ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const AdminLoadingView();
            }

            if (_errorMessage != null) {
              return AdminErrorView(
                message: _errorMessage!,
                onRetry: _loadData,
              );
            }

            if (_users.isEmpty) {
              return const AdminEmptyView(
                message: 'No hay usuarios registrados',
              );
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
              itemCount: _users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        user.fullName.isNotEmpty
                            ? user.fullName.characters.first.toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(user.fullName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(user.email),
                        const SizedBox(height: 2),
                        Text(
                          'Programa: ${user.programaAcademicoNombre?.trim().isNotEmpty == true ? user.programaAcademicoNombre : 'Sin programa'}',
                        ),
                        Text(
                          'Rol: ${user.roleName?.trim().isNotEmpty == true ? user.roleName : 'Sin rol'}',
                        ),
                        Text(
                          user.isActive ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            color: user.isActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openEditUserDialog(user);
                        } else if (value == 'delete') {
                          _deleteUser(user);
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

class _CreateUserPayload {
  const _CreateUserPayload({
    required this.email,
    required this.fullName,
    required this.password,
    required this.programaAcademicoId,
    required this.roleId,
    required this.isActive,
  });

  final String email;
  final String fullName;
  final String password;
  final int programaAcademicoId;
  final int roleId;
  final bool isActive;
}

class _EditUserPayload {
  const _EditUserPayload({
    this.fullName,
    this.programaAcademicoId,
    this.roleId,
    this.isActive,
  });

  final String? fullName;
  final int? programaAcademicoId;
  final int? roleId;
  final bool? isActive;
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog({
    required this.programs,
    required this.roles,
  });

  final List<AcademicProgram> programs;
  final List<AdminRoleOption> roles;

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();

  int? _programaAcademicoId;
  int? _roleId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.programs.isNotEmpty) {
      _programaAcademicoId = widget.programs.first.id;
    }
    if (widget.roles.isNotEmpty) {
      _roleId = widget.roles.first.id;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_programaAcademicoId == null || _roleId == null) {
      return;
    }

    Navigator.of(context).pop(
      _CreateUserPayload(
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        password: _passwordController.text,
        programaAcademicoId: _programaAcademicoId!,
        roleId: _roleId!,
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear usuario'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'El correo es obligatorio';
                  if (!text.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _fullNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                ),
                validator: (value) {
                  final text = value ?? '';
                  if (text.length < 8) return 'Mínimo 8 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _programaAcademicoId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Programa académico',
                ),
                items: widget.programs
                    .map(
                      (program) => DropdownMenuItem<int>(
                        value: program.id,
                        child: Text(program.nombre),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _programaAcademicoId = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _roleId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                ),
                items: widget.roles
                    .map(
                      (role) => DropdownMenuItem<int>(
                        value: role.id,
                        child: Text(role.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _roleId = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activo'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
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

class _EditUserDialog extends StatefulWidget {
  const _EditUserDialog({
    required this.user,
    required this.programs,
    required this.roles,
  });

  final AdminUserItem user;
  final List<AcademicProgram> programs;
  final List<AdminRoleOption> roles;

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;

  int? _programaAcademicoId;
  int? _roleId;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);

    _programaAcademicoId = widget.user.programaAcademicoId;
    if (_programaAcademicoId == null && widget.programs.isNotEmpty) {
      _programaAcademicoId = widget.programs.first.id;
    }

    _roleId = widget.user.roleId;
    if (_roleId == null && widget.roles.isNotEmpty) {
      _roleId = widget.roles.first.id;
    }

    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final normalizedName = _fullNameController.text.trim();
    final fullNameChanged = normalizedName != widget.user.fullName.trim();
    final programChanged = _programaAcademicoId != widget.user.programaAcademicoId;
    final roleChanged = _roleId != widget.user.roleId;
    final activeChanged = _isActive != widget.user.isActive;

    if (!fullNameChanged && !programChanged && !roleChanged && !activeChanged) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop(
      _EditUserPayload(
        fullName: fullNameChanged ? normalizedName : null,
        programaAcademicoId: programChanged ? _programaAcademicoId : null,
        roleId: roleChanged ? _roleId : null,
        isActive: activeChanged ? _isActive : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar usuario'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _programaAcademicoId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Programa académico',
                ),
                items: widget.programs
                    .map(
                      (program) => DropdownMenuItem<int>(
                        value: program.id,
                        child: Text(program.nombre),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _programaAcademicoId = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _roleId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                ),
                items: widget.roles
                    .map(
                      (role) => DropdownMenuItem<int>(
                        value: role.id,
                        child: Text(role.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _roleId = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activo'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
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
