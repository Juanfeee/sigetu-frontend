import 'package:flutter/material.dart';
import 'package:sigetu/core/utils/app_date_formatter.dart';
import 'package:sigetu/features/admin/presentation/widgets/admin_form_section_card.dart';

enum AdminHorarioMode { semanal, diasPersonalizados }

class AdminHorarioBlockDraft {
  AdminHorarioBlockDraft({this.horaInicio, this.horaFin});

  TimeOfDay? horaInicio;
  TimeOfDay? horaFin;
}

class AdminHorarioDiaDraft {
  AdminHorarioDiaDraft({
    required this.diaSemana,
    List<AdminHorarioBlockDraft>? bloques,
  }) : bloques = bloques ?? [AdminHorarioBlockDraft()];

  int diaSemana;
  final List<AdminHorarioBlockDraft> bloques;
}

class AdminWeekdayOption {
  const AdminWeekdayOption({required this.value, required this.label});

  final int value;
  final String label;
}

class AdminSedeHorariosStep extends StatelessWidget {
  const AdminSedeHorariosStep({
    super.key,
    required this.mode,
    required this.weeklyDays,
    required this.weeklyBlocks,
    required this.customDays,
    required this.isLoading,
    required this.infoMessage,
    required this.errorMessage,
    required this.onModeChanged,
    required this.onToggleWeeklyDay,
    required this.onPickWeeklyTime,
    required this.onAddWeeklyBlock,
    required this.onRemoveWeeklyBlock,
    required this.onAddCustomDay,
    required this.onRemoveCustomDay,
    required this.onCustomDayChanged,
    required this.onPickCustomTime,
    required this.onAddCustomBlock,
    required this.onRemoveCustomBlock,
  });

  final AdminHorarioMode mode;
  final Set<int> weeklyDays;
  final List<AdminHorarioBlockDraft> weeklyBlocks;
  final List<AdminHorarioDiaDraft> customDays;
  final bool isLoading;
  final String? infoMessage;
  final String? errorMessage;

  final ValueChanged<AdminHorarioMode> onModeChanged;
  final void Function(int day, bool selected) onToggleWeeklyDay;
  final void Function(int blockIndex, bool isStart) onPickWeeklyTime;
  final VoidCallback onAddWeeklyBlock;
  final ValueChanged<int> onRemoveWeeklyBlock;

  final VoidCallback onAddCustomDay;
  final ValueChanged<int> onRemoveCustomDay;
  final void Function(int dayIndex, int dayValue) onCustomDayChanged;
  final void Function(int dayIndex, int blockIndex, bool isStart)
  onPickCustomTime;
  final ValueChanged<int> onAddCustomBlock;
  final void Function(int dayIndex, int blockIndex) onRemoveCustomBlock;

  static const List<AdminWeekdayOption> _weekdayOptions = [
    AdminWeekdayOption(value: 1, label: 'Lunes'),
    AdminWeekdayOption(value: 2, label: 'Martes'),
    AdminWeekdayOption(value: 3, label: 'Miércoles'),
    AdminWeekdayOption(value: 4, label: 'Jueves'),
    AdminWeekdayOption(value: 5, label: 'Viernes'),
    AdminWeekdayOption(value: 6, label: 'Sábado'),
    AdminWeekdayOption(value: 7, label: 'Domingo'),
  ];

  String _formatTimeLabel(TimeOfDay? time) {
    if (time == null) return '--:--';
    return AppDateFormatter.time12(time);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFormSectionCard(
          icon: Icons.tune_outlined,
          title: 'Modo de configuración',
          subtitle:
              'Selecciona cómo deseas configurar los horarios de atención',
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('Semanal'),
                selected: mode == AdminHorarioMode.semanal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: isLoading
                    ? null
                    : (_) => onModeChanged(AdminHorarioMode.semanal),
              ),
              ChoiceChip(
                label: const Text('Días personalizados'),
                selected: mode == AdminHorarioMode.diasPersonalizados,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: isLoading
                    ? null
                    : (_) => onModeChanged(AdminHorarioMode.diasPersonalizados),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (mode == AdminHorarioMode.semanal) _buildWeeklyEditor(),
        if (mode == AdminHorarioMode.diasPersonalizados)
          _buildCustomDaysEditor(),
        if (infoMessage != null) ...[
          const SizedBox(height: 10),
          _buildStatusMessage(
            context: context,
            message: infoMessage!,
            isError: false,
          ),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 10),
          _buildStatusMessage(
            context: context,
            message: errorMessage!,
            isError: true,
          ),
        ],
      ],
    );
  }

  Widget _buildWeeklyEditor() {
    final dayGridChildren = _weekdayOptions.map((option) {
      final selected = weeklyDays.contains(option.value);
      return _buildDayTile(
        label: option.label,
        selected: selected,
        onTap: isLoading
            ? null
            : () => onToggleWeeklyDay(option.value, !selected),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFormSectionCard(
          icon: Icons.calendar_month_outlined,
          title: 'Días de Atención',
          subtitle: 'Selecciona los días de la semana en que la sede atiende',
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 1,
            crossAxisSpacing: 5,
            childAspectRatio: 2.9,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: dayGridChildren,
          ),
        ),
        const SizedBox(height: 14),
        AdminFormSectionCard(
          icon: Icons.access_time_rounded,
          title: 'Horario de Atención',
          subtitle: 'Configura uno o más bloques semanales',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < weeklyBlocks.length; i++) ...[
                _buildScheduleBlockRow(
                  startLabel: 'Hora de Inicio',
                  endLabel: 'Hora de Cierre',
                  startValue: _formatTimeLabel(weeklyBlocks[i].horaInicio),
                  endValue: _formatTimeLabel(weeklyBlocks[i].horaFin),
                  onPickStart: isLoading ? null : () => onPickWeeklyTime(i, true),
                  onPickEnd: isLoading ? null : () => onPickWeeklyTime(i, false),
                  onDelete: isLoading ? null : () => onRemoveWeeklyBlock(i),
                ),
                if (i < weeklyBlocks.length - 1) const SizedBox(height: 8),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: isLoading ? null : onAddWeeklyBlock,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar bloque semanal'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField({
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayTile({
    required String label,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scheme = Theme.of(context).colorScheme;

        return ConstrainedBox(
          constraints: BoxConstraints.tightFor(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          ),
          child: ChoiceChip(
            selected: selected,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            showCheckmark: false,
            labelPadding: const EdgeInsets.symmetric(horizontal: 10),
            label: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 14,
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: selected
                        ? scheme.onSecondaryContainer
                        : Colors.transparent,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
            onSelected: onTap == null ? null : (_) => onTap(),
          ),
        );
      },
    );
  }

  Widget _buildScheduleBlockRow({
    required String startLabel,
    required String endLabel,
    required String startValue,
    required String endValue,
    required VoidCallback? onPickStart,
    required VoidCallback? onPickEnd,
    required VoidCallback? onDelete,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;

        final startField = _buildTimeField(
          label: startLabel,
          value: startValue,
          onTap: onPickStart,
        );
        final endField = _buildTimeField(
          label: endLabel,
          value: endValue,
          onTap: onPickEnd,
        );

        final deleteButton = IconButton(
          tooltip: 'Eliminar bloque',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              startField,
              const SizedBox(height: 8),
              endField,
              Align(alignment: Alignment.centerRight, child: deleteButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: startField),
            const SizedBox(width: 8),
            Expanded(child: endField),
            deleteButton,
          ],
        );
      },
    );
  }

  Widget _buildStatusMessage({
    required BuildContext context,
    required String message,
    required bool isError,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = isError ? scheme.error : scheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDaysEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var dayIndex = 0; dayIndex < customDays.length; dayIndex++) ...[
          AdminFormSectionCard(
            icon: Icons.date_range_outlined,
            title: 'Día personalizado ${dayIndex + 1}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  value: customDays[dayIndex].diaSemana,
                  decoration: const InputDecoration(
                    labelText: 'Día',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _weekdayOptions
                      .map(
                        (option) => DropdownMenuItem<int>(
                          value: option.value,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: isLoading
                      ? null
                      : (value) {
                          if (value != null) {
                            onCustomDayChanged(dayIndex, value);
                          }
                        },
                ),
                const SizedBox(height: 10),
                for (
                  var blockIndex = 0;
                  blockIndex < customDays[dayIndex].bloques.length;
                  blockIndex++
                ) ...[
                  _buildScheduleBlockRow(
                    startLabel: 'Hora de Inicio',
                    endLabel: 'Hora de Cierre',
                    startValue: _formatTimeLabel(
                      customDays[dayIndex].bloques[blockIndex].horaInicio,
                    ),
                    endValue: _formatTimeLabel(
                      customDays[dayIndex].bloques[blockIndex].horaFin,
                    ),
                    onPickStart: isLoading
                        ? null
                        : () => onPickCustomTime(dayIndex, blockIndex, true),
                    onPickEnd: isLoading
                        ? null
                        : () => onPickCustomTime(dayIndex, blockIndex, false),
                    onDelete: isLoading
                        ? null
                        : () => onRemoveCustomBlock(dayIndex, blockIndex),
                  ),
                  if (blockIndex < customDays[dayIndex].bloques.length - 1)
                    const SizedBox(height: 8),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => onAddCustomBlock(dayIndex),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar bloque para este día'),
                    ),
                    TextButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => onRemoveCustomDay(dayIndex),
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: const Text('Eliminar este día'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (dayIndex < customDays.length - 1) const SizedBox(height: 14),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: isLoading ? null : onAddCustomDay,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Agregar otro día personalizado'),
          ),
        ),
      ],
    );
  }
}
