import 'package:flutter/material.dart';
import 'package:sigetu/core/utils/responsive.dart';
import 'package:sigetu/core/widgets/app_toast.dart';
import 'package:sigetu/features/admin/data/admin_sede_roles_api.dart';
import 'package:sigetu/features/admin/data/admin_sedes_api.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_form_action_buttons.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_page_container.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_form_section_card.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_page_header.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_toggle_card.dart';
import 'package:sigetu/features/headquarters/domain/sede.dart';

class AdminSedeCreateScreen extends StatefulWidget {
  const AdminSedeCreateScreen({super.key, this.initialSede});

  final Sede? initialSede;

  @override
  State<AdminSedeCreateScreen> createState() => _AdminSedeCreateScreenState();
}

class _AdminSedeCreateScreenState extends State<AdminSedeCreateScreen> {
  final _api = AdminSedesApi();
  final _rolesApi = AdminSedeRolesApi();
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _descripcionController = TextEditingController();

  // List<AdminRole> _roles = [];
  // int? _selectedRoleId;
  // bool _isLoadingRoles = true;
  // String? _rolesErrorMessage;

  bool _esPublica = true;
  bool _filtrarCitasPorPrograma = false;
  bool _activo = true;
  bool _isSubmitting = false;
  bool _showStaffStep = false;
  bool _isLoadingStaff = false;
  bool _isAssigningStaff = false;

  int? _createdSedeId;
  List<AdminStaffUser> _staffUsers = [];
  final Set<int> _selectedStaffUserIds = <int>{};
  String _staffSearchQuery = '';
  String? _staffInfoMessage;
  String? _staffErrorMessage;

  bool get _isEditing => widget.initialSede != null;

  @override
  void initState() {
    super.initState();
    final initialSede = widget.initialSede;
    if (initialSede != null) {
      _codigoController.text = initialSede.codigo;
      _nombreController.text = initialSede.nombre;
      _ubicacionController.text = initialSede.ubicacion ?? '';
      _descripcionController.text = initialSede.descripcion ?? '';
      _esPublica = initialSede.esPublica;
      _filtrarCitasPorPrograma = initialSede.filtrarCitasPorPrograma;
      _activo = initialSede.activo;
      // _selectedRoleId = initialSede.roleId;
    }
    // _loadRoles();
  }

  // --- Eliminada lógica de roles ---

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _ubicacionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      String? message;

      if (_isEditing) {
        message = await _api.updateSede(
          widget.initialSede!.id,
          codigo: _codigoController.text.trim(),
          nombre: _nombreController.text.trim(),
          ubicacion: _ubicacionController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          esPublica: _esPublica,
          filtrarCitasPorPrograma: _filtrarCitasPorPrograma,
          activo: _activo,
        );
      } else {
        final result = await _api.createSede(
          codigo: _codigoController.text.trim(),
          nombre: _nombreController.text.trim(),
          ubicacion: _ubicacionController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          esPublica: _esPublica,
          filtrarCitasPorPrograma: _filtrarCitasPorPrograma,
          activo: _activo,
        );
        if (!mounted) return;

        final createdSedeId = result.sedeId;
        if (createdSedeId == null || createdSedeId <= 0) {
          throw Exception(
            'Se creó la sede, pero el backend no retornó el id para asignar staff.',
          );
        }

        setState(() {
          _createdSedeId = createdSedeId;
          _showStaffStep = true;
          _staffInfoMessage =
              result.message ?? 'Sede creada correctamente. Ahora asigna staff.';
          _staffErrorMessage = null;
          _staffSearchQuery = '';
          _staffUsers = [];
          _selectedStaffUserIds.clear();
        });
        await _loadStaffUsers();
        return;
      }

      if (!mounted) return;
      await AppToast.showSuccess(
        context,
        message: message ?? (_isEditing ? 'Sede actualizada' : 'Sede creada correctamente'),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      await AppToast.showError(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _loadStaffUsers() async {
    setState(() {
      _isLoadingStaff = true;
      _staffErrorMessage = null;
    });

    try {
      final staffUsers = await _rolesApi.fetchStaffUsers();
      if (!mounted) return;
      setState(() {
        _staffUsers = staffUsers;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _staffErrorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStaff = false;
        });
      }
    }
  }

  Future<void> _assignSelectedStaff() async {
    if (_createdSedeId == null || _createdSedeId! <= 0) {
      setState(() {
        _staffErrorMessage = 'No hay id de sede para asignar staff.';
      });
      return;
    }

    if (_selectedStaffUserIds.isEmpty) {
      setState(() {
        _staffErrorMessage = 'Selecciona al menos un usuario staff.';
      });
      return;
    }

    setState(() {
      _isAssigningStaff = true;
      _staffErrorMessage = null;
    });

    var successCount = 0;
    final failures = <String>[];

    for (final userId in _selectedStaffUserIds) {
      try {
        await _rolesApi.assignStaffToSede(
          userId: userId,
          sedeId: _createdSedeId!,
        );
        successCount++;
      } catch (error) {
        failures.add(error.toString().replaceFirst('Exception: ', ''));
      }
    }

    if (!mounted) return;

    setState(() {
      _isAssigningStaff = false;
      if (successCount > 0) {
        _staffInfoMessage = 'Se asignaron $successCount staff a la sede.';
      }
      if (failures.isNotEmpty) {
        final detail = failures.first;
        _staffErrorMessage = successCount > 0
            ? 'Algunas asignaciones fallaron: $detail'
            : 'No se pudo asignar staff: $detail';
      }
    });
  }

  Widget _buildStepIndicator() {
    final currentStep = _showStaffStep && !_isEditing ? 2 : 1;
    const totalSteps = 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Icon(Icons.format_list_numbered, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Text('Paso $currentStep de $totalSteps'),
        ],
      ),
    );
  }

  Widget _buildFormStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AdminFormSectionCard(
            icon: Icons.badge_outlined,
            title: 'Nombre de la Sede',
            child: TextFormField(
              controller: _nombreController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Ej: Sede Administrativa',
                border: InputBorder.none,
                isDense: true,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 2) return 'Mínimo 2 caracteres';
                if (text.length > 120) return 'Máximo 120 caracteres';
                return null;
              },
            ),
          ),
          const SizedBox(height: 14),
          AdminFormSectionCard(
            icon: Icons.location_on_outlined,
            title: 'Dirección',
            child: TextFormField(
              controller: _ubicacionController,
              textInputAction: TextInputAction.next,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ej: Calle 5 # 3-85, Popayán',
                border: InputBorder.none,
                isDense: true,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 1) return 'La ubicación es obligatoria';
                if (text.length > 255) return 'Máximo 255 caracteres';
                return null;
              },
            ),
          ),
          const SizedBox(height: 14),
          AdminFormSectionCard(
            icon: Icons.confirmation_number_outlined,
            title: 'Código interno',
            child: TextFormField(
              controller: _codigoController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Ej: sede123',
                border: InputBorder.none,
                isDense: true,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 2) return 'Mínimo 2 caracteres';
                if (text.length > 50) return 'Máximo 50 caracteres';
                return null;
              },
            ),
          ),
          const SizedBox(height: 14),
          AdminFormSectionCard(
            icon: Icons.notes_outlined,
            title: 'Descripción',
            subtitle: 'Opcional',
            child: TextFormField(
              controller: _descripcionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Descripción breve de la sede',
                border: InputBorder.none,
                isDense: true,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length > 255) return 'Máximo 255 caracteres';
                return null;
              },
            ),
          ),
          const SizedBox(height: 14),
          AdminToggleCard(
            items: [
              AdminToggleItem(
                title: 'Es pública',
                value: _esPublica,
                onChanged: (value) => setState(() => _esPublica = value),
              ),
              AdminToggleItem(
                title: 'Filtrar citas por programa',
                value: _filtrarCitasPorPrograma,
                onChanged: (value) => setState(() => _filtrarCitasPorPrograma = value),
              ),
              AdminToggleItem(
                title: 'Activa',
                value: _activo,
                onChanged: (value) => setState(() => _activo = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffStep() {
    final normalizedQuery = _staffSearchQuery.trim().toLowerCase();
    final filteredStaffUsers = normalizedQuery.isEmpty
        ? _staffUsers
        : _staffUsers.where((staff) {
            final name = staff.fullName.toLowerCase();
            final email = staff.email.toLowerCase();
            return name.contains(normalizedQuery) || email.contains(normalizedQuery);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFormSectionCard(
          icon: Icons.group_add_outlined,
          title: 'Asignar Staff',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_staffInfoMessage != null) ...[
                Text(
                  _staffInfoMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 10),
              ],
              if (_staffErrorMessage != null) ...[
                Text(
                  _staffErrorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                onChanged: (value) {
                  setState(() {
                    _staffSearchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre o correo',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              if (_isLoadingStaff)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_staffUsers.isEmpty)
                const Text('No hay usuarios staff disponibles.')
              else if (filteredStaffUsers.isEmpty)
                const Text('No hay resultados para la búsqueda.')
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredStaffUsers.length,
                    itemBuilder: (context, index) {
                      final staff = filteredStaffUsers[index];
                      final isSelected = _selectedStaffUserIds.contains(staff.id);
                      return CheckboxListTile(
                        value: isSelected,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(staff.displayLabel),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedStaffUserIds.add(staff.id);
                            } else {
                              _selectedStaffUserIds.remove(staff.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.horizontalPadding(context);
    final screenTitle = _isEditing ? 'Editar Sede' : 'Nueva Sede';
    return AdminPageContainer(
      title: screenTitle,
      body: ListView(
          padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 24),
          children: [
            AdminPageHeader(
              title: screenTitle,
              subtitle: _isEditing
                  ? 'Actualiza la información de la sede'
                  : (_showStaffStep
                      ? 'Paso 2: asigna los usuarios staff a la sede'
                      : 'Paso 1: registra la información de la sede'),
              icon: _isEditing ? Icons.edit_location_alt_outlined : Icons.apartment_outlined,
            ),
            const SizedBox(height: 18),
            if (!_isEditing) ...[
              _buildStepIndicator(),
              const SizedBox(height: 14),
            ],
            _showStaffStep && !_isEditing ? _buildStaffStep() : _buildFormStep(),
            const SizedBox(height: 20),
            if (_showStaffStep && !_isEditing)
              AdminFormActionButtons(
                primaryLabel: 'Asignar seleccionados',
                primaryOnPressed: _isAssigningStaff ? null : _assignSelectedStaff,
                secondaryLabel: 'Finalizar',
                secondaryOnPressed: () => Navigator.of(context).pop(true),
                isPrimaryLoading: _isAssigningStaff,
              )
            else
              AdminFormActionButtons(
                primaryLabel: _isEditing ? 'Actualizar sede' : 'Guardar y continuar',
                primaryOnPressed: _submit,
                secondaryLabel: 'Volver',
                secondaryOnPressed: () => Navigator.of(context).pop(),
                isPrimaryLoading: _isSubmitting,
              ),
          ],
      ),
    );
  }
}

