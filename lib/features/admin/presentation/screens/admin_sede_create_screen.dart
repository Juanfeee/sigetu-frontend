import 'package:flutter/material.dart';
import 'package:sigetu/core/utils/responsive.dart';
import 'package:sigetu/core/widgets/app_toast.dart';
import 'package:sigetu/features/admin/data/admin_sede_roles_api.dart';
import 'package:sigetu/features/admin/data/admin_sedes_api.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_form_action_buttons.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_page_container.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_page_header.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_sede_form_step.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_sede_horarios_step.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_sede_staff_step.dart';
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

  bool _esPublica = true;
  bool _filtrarCitasPorPrograma = false;
  bool _activo = true;

  bool _isSubmitting = false;
  bool _isSavingHorarios = false;
  bool _isLoadingStaff = false;
  bool _isAssigningStaff = false;

  int _creationStep = 1;
  int? _createdSedeId;

  AdminHorarioMode _horarioMode = AdminHorarioMode.semanal;
  final Set<int> _weeklyDays = <int>{};
  final List<AdminHorarioBlockDraft> _weeklyBlocks = <AdminHorarioBlockDraft>[
    AdminHorarioBlockDraft(),
  ];
  final List<AdminHorarioDiaDraft> _customDays = <AdminHorarioDiaDraft>[
    AdminHorarioDiaDraft(diaSemana: 1),
  ];

  List<AdminStaffUser> _staffUsers = [];
  List<AdminStaffUser> _sedeStaffUsers = [];
  final Set<int> _selectedStaffUserIds = <int>{};
  String _staffSearchQuery = '';

  String? _horariosInfoMessage;
  String? _horariosErrorMessage;
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
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _ubicacionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _submitSede() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isEditing) {
        final message = await _api.updateSede(
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

        if (!mounted) return;
        await AppToast.showSuccess(
          context,
          message: message ?? 'Sede actualizada',
        );
        Navigator.of(context).pop(true);
        return;
      }

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
          'Se creó la sede, pero el backend no retornó el id para continuar.',
        );
      }

      setState(() {
        _createdSedeId = createdSedeId;
        _creationStep = 2;
        _resetHorarioDraft();
        _staffUsers = [];
        _sedeStaffUsers = [];
        _selectedStaffUserIds.clear();
        _staffSearchQuery = '';
        _staffInfoMessage = null;
        _staffErrorMessage = null;
        _horariosInfoMessage = result.message ?? 'Sede creada correctamente.';
        _horariosErrorMessage = null;
      });
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

  void _resetHorarioDraft() {
    _horarioMode = AdminHorarioMode.semanal;
    _weeklyDays.clear();
    _weeklyBlocks
      ..clear()
      ..add(AdminHorarioBlockDraft());
    _customDays
      ..clear()
      ..add(AdminHorarioDiaDraft(diaSemana: 1));
  }

  Future<void> _pickTimeForWeeklyBlock(int blockIndex, bool isStart) async {
    if (blockIndex < 0 || blockIndex >= _weeklyBlocks.length) return;

    final block = _weeklyBlocks[blockIndex];
    final initialTime = isStart
        ? (block.horaInicio ?? const TimeOfDay(hour: 8, minute: 0))
        : (block.horaFin ?? const TimeOfDay(hour: 12, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isStart ? 'Selecciona hora de inicio' : 'Selecciona hora de fin',
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        block.horaInicio = picked;
      } else {
        block.horaFin = picked;
      }
    });
  }

  Future<void> _pickTimeForCustomBlock(
    int dayIndex,
    int blockIndex,
    bool isStart,
  ) async {
    if (dayIndex < 0 || dayIndex >= _customDays.length) return;
    if (blockIndex < 0 || blockIndex >= _customDays[dayIndex].bloques.length) return;

    final block = _customDays[dayIndex].bloques[blockIndex];
    final initialTime = isStart
        ? (block.horaInicio ?? const TimeOfDay(hour: 8, minute: 0))
        : (block.horaFin ?? const TimeOfDay(hour: 12, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isStart ? 'Selecciona hora de inicio' : 'Selecciona hora de fin',
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        block.horaInicio = picked;
      } else {
        block.horaFin = picked;
      }
    });
  }

  String _toBackendTime(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }

  String? _validateBlock(AdminHorarioBlockDraft block, String label) {
    if (block.horaInicio == null || block.horaFin == null) {
      return 'Completa hora inicio y fin para $label.';
    }

    final startMinutes = block.horaInicio!.hour * 60 + block.horaInicio!.minute;
    final endMinutes = block.horaFin!.hour * 60 + block.horaFin!.minute;

    if (endMinutes <= startMinutes) {
      return 'La hora fin debe ser mayor que inicio en $label.';
    }

    return null;
  }

  List<Map<String, dynamic>> _buildHorariosLotePayload() {
    final bloques = <Map<String, dynamic>>[];

    if (_horarioMode == AdminHorarioMode.semanal) {
      if (_weeklyDays.isEmpty) {
        throw Exception('Selecciona al menos un día laboral.');
      }
      if (_weeklyBlocks.isEmpty) {
        throw Exception('Agrega al menos un bloque semanal.');
      }

      final orderedDays = _weeklyDays.toList()..sort();
      for (var i = 0; i < _weeklyBlocks.length; i++) {
        final block = _weeklyBlocks[i];
        final error = _validateBlock(block, 'bloque semanal ${i + 1}');
        if (error != null) throw Exception(error);

        for (final day in orderedDays) {
          bloques.add({
            'dia_semana': day,
            'hora_inicio': _toBackendTime(block.horaInicio!),
            'hora_fin': _toBackendTime(block.horaFin!),
            'activo': true,
          });
        }
      }
      return bloques;
    }

    if (_customDays.isEmpty) {
      throw Exception('Agrega al menos un día personalizado.');
    }

    for (var dayIndex = 0; dayIndex < _customDays.length; dayIndex++) {
      final draft = _customDays[dayIndex];
      if (draft.bloques.isEmpty) {
        throw Exception('El día personalizado ${dayIndex + 1} no tiene bloques.');
      }

      for (var blockIndex = 0; blockIndex < draft.bloques.length; blockIndex++) {
        final block = draft.bloques[blockIndex];
        final error = _validateBlock(
          block,
          'día ${dayIndex + 1}, bloque ${blockIndex + 1}',
        );
        if (error != null) throw Exception(error);

        bloques.add({
          'dia_semana': draft.diaSemana,
          'hora_inicio': _toBackendTime(block.horaInicio!),
          'hora_fin': _toBackendTime(block.horaFin!),
          'activo': true,
        });
      }
    }

    return bloques;
  }

  Future<void> _saveHorariosAndContinue() async {
    if (_createdSedeId == null || _createdSedeId! <= 0) {
      setState(() {
        _horariosErrorMessage = 'No hay id de sede para registrar horarios.';
      });
      return;
    }

    setState(() {
      _isSavingHorarios = true;
      _horariosErrorMessage = null;
    });

    try {
      final bloques = _buildHorariosLotePayload();
      final message = await _api.createHorariosSedeLote(
        _createdSedeId!,
        bloques: bloques,
      );

      if (!mounted) return;

      setState(() {
        _creationStep = 3;
        _horariosInfoMessage = message ?? 'Horarios guardados correctamente.';
        _staffInfoMessage = 'Horarios registrados. Ahora asigna usuarios staff.';
        _staffErrorMessage = null;
      });

      await _loadStaffUsers();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _horariosErrorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingHorarios = false;
        });
      }
    }
  }

  Future<void> _loadStaffUsers() async {
    final sedeId = _createdSedeId;
    if (sedeId == null || sedeId <= 0) {
      setState(() {
        _staffUsers = [];
        _sedeStaffUsers = [];
        _staffErrorMessage = 'No hay id de sede para consultar staff.';
      });
      return;
    }

    setState(() {
      _isLoadingStaff = true;
      _staffErrorMessage = null;
    });

    try {
      final results = await Future.wait<List<AdminStaffUser>>([
        _rolesApi.fetchStaffUsers(sinSede: true),
        _rolesApi.fetchStaffBySede(sedeId: sedeId, activo: true),
      ]);

      final staffUsers = results[0];
      final sedeStaffUsers = results[1];
      if (!mounted) return;
      setState(() {
        _staffUsers = staffUsers;
        _sedeStaffUsers = sedeStaffUsers;
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
    final successfullyAssigned = <int>[];

    for (final userId in _selectedStaffUserIds) {
      try {
        await _rolesApi.assignStaffToSede(
          userId: userId,
          sedeId: _createdSedeId!,
        );
        successCount++;
        successfullyAssigned.add(userId);
      } catch (error) {
        failures.add(error.toString().replaceFirst('Exception: ', ''));
      }
    }

    if (!mounted) return;

    setState(() {
      _isAssigningStaff = false;
      for (final userId in successfullyAssigned) {
        _selectedStaffUserIds.remove(userId);
      }
      if (successCount > 0) {
        _staffInfoMessage = 'Se asignaron $successCount staff a la sede.';
      }
      if (failures.isNotEmpty) {
        _staffErrorMessage = successCount > 0
            ? 'Algunas asignaciones fallaron: ${failures.first}'
            : 'No se pudo asignar staff: ${failures.first}';
      }
    });

    if (successCount > 0) {
      await _loadStaffUsers();
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Icon(
            Icons.format_list_numbered,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Text('Paso $_creationStep de 3'),
        ],
      ),
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
                : _creationStep == 1
                    ? 'Paso 1: registra la información de la sede'
                    : _creationStep == 2
                        ? 'Paso 2: configura horarios por lote'
                        : 'Paso 3: asigna los usuarios staff a la sede',
            icon: _isEditing ? Icons.edit_location_alt_outlined : Icons.apartment_outlined,
          ),
          const SizedBox(height: 18),
          if (!_isEditing) ...[
            _buildStepIndicator(),
            const SizedBox(height: 14),
          ],
          if (_isEditing || _creationStep == 1)
            AdminSedeFormStep(
              formKey: _formKey,
              codigoController: _codigoController,
              nombreController: _nombreController,
              ubicacionController: _ubicacionController,
              descripcionController: _descripcionController,
              esPublica: _esPublica,
              filtrarCitasPorPrograma: _filtrarCitasPorPrograma,
              activo: _activo,
              onEsPublicaChanged: (value) => setState(() => _esPublica = value),
              onFiltrarCitasChanged: (value) => setState(() => _filtrarCitasPorPrograma = value),
              onActivoChanged: (value) => setState(() => _activo = value),
            )
          else if (_creationStep == 2)
            AdminSedeHorariosStep(
              mode: _horarioMode,
              weeklyDays: _weeklyDays,
              weeklyBlocks: _weeklyBlocks,
              customDays: _customDays,
              isLoading: _isSavingHorarios,
              infoMessage: _horariosInfoMessage,
              errorMessage: _horariosErrorMessage,
              onModeChanged: (value) {
                setState(() {
                  _horarioMode = value;
                  _horariosErrorMessage = null;
                });
              },
              onToggleWeeklyDay: (day, selected) {
                setState(() {
                  if (selected) {
                    _weeklyDays.add(day);
                  } else {
                    _weeklyDays.remove(day);
                  }
                });
              },
              onPickWeeklyTime: _pickTimeForWeeklyBlock,
              onAddWeeklyBlock: () {
                setState(() {
                  _weeklyBlocks.add(AdminHorarioBlockDraft());
                });
              },
              onRemoveWeeklyBlock: (index) {
                if (_weeklyBlocks.length == 1) return;
                setState(() {
                  _weeklyBlocks.removeAt(index);
                });
              },
              onAddCustomDay: () {
                setState(() {
                  _customDays.add(AdminHorarioDiaDraft(diaSemana: 1));
                });
              },
              onRemoveCustomDay: (dayIndex) {
                if (_customDays.length == 1) return;
                setState(() {
                  _customDays.removeAt(dayIndex);
                });
              },
              onCustomDayChanged: (dayIndex, dayValue) {
                setState(() {
                  _customDays[dayIndex].diaSemana = dayValue;
                });
              },
              onPickCustomTime: _pickTimeForCustomBlock,
              onAddCustomBlock: (dayIndex) {
                setState(() {
                  _customDays[dayIndex].bloques.add(AdminHorarioBlockDraft());
                });
              },
              onRemoveCustomBlock: (dayIndex, blockIndex) {
                if (_customDays[dayIndex].bloques.length == 1) return;
                setState(() {
                  _customDays[dayIndex].bloques.removeAt(blockIndex);
                });
              },
            )
          else
            AdminSedeStaffStep(
              staffUsers: _staffUsers,
              sedeStaffUsers: _sedeStaffUsers,
              selectedStaffUserIds: _selectedStaffUserIds,
              searchQuery: _staffSearchQuery,
              isLoading: _isLoadingStaff,
              infoMessage: _staffInfoMessage,
              errorMessage: _staffErrorMessage,
              onSearchChanged: (value) {
                setState(() {
                  _staffSearchQuery = value;
                });
              },
              onToggleUser: (userId) {
                setState(() {
                  if (_selectedStaffUserIds.contains(userId)) {
                    _selectedStaffUserIds.remove(userId);
                  } else {
                    _selectedStaffUserIds.add(userId);
                  }
                });
              },
            ),
          const SizedBox(height: 20),
          if (!_isEditing && _creationStep == 3)
            AdminFormActionButtons(
              primaryLabel: 'Asignar seleccionados',
              primaryOnPressed: _isAssigningStaff ? null : _assignSelectedStaff,
              secondaryLabel: 'Finalizar',
              secondaryOnPressed: () => Navigator.of(context).pop(true),
              isPrimaryLoading: _isAssigningStaff,
            )
          else if (!_isEditing && _creationStep == 2)
            AdminFormActionButtons(
              primaryLabel: 'Guardar horarios y continuar',
              primaryOnPressed: _isSavingHorarios ? null : _saveHorariosAndContinue,
              secondaryLabel: 'Volver a datos',
              secondaryOnPressed: _isSavingHorarios
                  ? null
                  : () {
                      setState(() {
                        _creationStep = 1;
                      });
                    },
              isPrimaryLoading: _isSavingHorarios,
            )
          else
            AdminFormActionButtons(
              primaryLabel: _isEditing ? 'Actualizar sede' : 'Guardar y continuar',
              primaryOnPressed: _submitSede,
              secondaryLabel: 'Volver',
              secondaryOnPressed: () => Navigator.of(context).pop(),
              isPrimaryLoading: _isSubmitting,
            ),
        ],
      ),
    );
  }
}
