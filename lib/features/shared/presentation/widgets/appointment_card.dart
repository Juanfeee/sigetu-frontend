import 'package:flutter/material.dart';
import 'package:sigetu/core/constants/appointment_statuses.dart';
import 'package:sigetu/core/utils/app_date_formatter.dart';
import 'package:sigetu/features/secretary/domain/secretary_appointment.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onOpenTurn,
    this.isLoading = false,
  });

  final SecretaryAppointment appointment;
  final VoidCallback onOpenTurn;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final infoIconColor = scheme.onSurface.withValues(alpha: 0.58);
    final primaryTone = scheme.primary;
    final titleTone = scheme.onSurface;
    final detailText = appointment.context.trim().isNotEmpty
        ? _titleCase(appointment.context)
        : _titleCase(appointment.category);
    final secretariaLabel =
        (appointment.secretariaName == null ||
            appointment.secretariaName!.trim().isEmpty)
        ? 'Sin asignar'
        : appointment.secretariaName!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: titleTone,
                                  ),
                          children: [
                            const TextSpan(text: 'Turno '),
                            TextSpan(
                              text: appointment.turnNumber,
                              style: TextStyle(
                                color: primaryTone,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(context, appointment.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.person_outline,
                        color: infoIconColor,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.studentName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            detailText,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.86),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.support_agent_outlined,
                      size: 18,
                      color: infoIconColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Atendiendo por: $secretariaLabel',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface.withValues(alpha: 0.86),
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: infoIconColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppDateFormatter.dateShort(
                              appointment.scheduledAt,
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: infoIconColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppDateFormatter.time12FromDateTime(
                              appointment.scheduledAt,
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Semantics(
                  button: true,
                  label: 'Abrir turno ${appointment.turnNumber}',
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : onOpenTurn,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: scheme.primary.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        foregroundColor: scheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: isLoading
                          ? SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.primary,
                              ),
                            )
                          : const Icon(
                              Icons.open_in_new_outlined,
                              size: 18,
                            ),
                      label: const Text(
                        'Abrir turno',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _titleCase(String value) {
    return value
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _statusLabel(String status) {
    switch (status) {
      case AppointmentStatuses.attended:
        return 'Atendido';
      case AppointmentStatuses.absent:
        return 'No asistió';
      case AppointmentStatuses.canceled:
        return 'Cancelada';
      case AppointmentStatuses.calling:
        return 'Llamando';
      case AppointmentStatuses.pending:
        return 'Pendiente';
      default:
        return _titleCase(status);
    }
  }

  String _normalizeStatus(String status) => status.trim().toLowerCase();

  Color _statusColor(BuildContext context, String status) {
    final normalized = _normalizeStatus(status);
    final scheme = Theme.of(context).colorScheme;

    if (normalized == AppointmentStatuses.attended) {
      return scheme.secondary;
    }

    if (normalized == AppointmentStatuses.absent ||
        normalized == AppointmentStatuses.canceled) {
      return scheme.error;
    }

    if (normalized == AppointmentStatuses.calling) {
      return scheme.primary;
    }

    if (normalized == AppointmentStatuses.inAttention ||
        normalized == 'atendiendo') {
      return scheme.secondary;
    }

    return scheme.outline;
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final statusColor = _statusColor(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: statusColor.withValues(alpha: 0.28)),
      ),
      child: Text(
        _statusLabel(status),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
