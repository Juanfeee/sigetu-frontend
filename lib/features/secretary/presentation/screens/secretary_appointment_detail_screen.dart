import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sigetu/core/constants/appointment_statuses.dart';
import 'package:sigetu/core/utils/app_date_formatter.dart';
import 'package:sigetu/core/utils/responsive.dart';
import 'package:sigetu/core/widgets/app_toast.dart';
import 'package:sigetu/features/secretary/data/secretary_appointments_api.dart';
import 'package:sigetu/features/secretary/domain/secretary_appointment_detail.dart';
import 'package:sigetu/features/secretary/presentation/widgets/secretary_status_action_button.dart';

class SecretaryAppointmentDetailScreen extends StatefulWidget {
  const SecretaryAppointmentDetailScreen({super.key, required this.detail});

  final SecretaryAppointmentDetail detail;

  @override
  State<SecretaryAppointmentDetailScreen> createState() =>
      _SecretaryAppointmentDetailScreenState();
}

class _SecretaryAppointmentDetailScreenState
    extends State<SecretaryAppointmentDetailScreen> {
  final _api = SecretaryAppointmentsApi();
  String? _updatingStatus;
  late String _currentStatus;
  Timer? _countdownTimer;
  DateTime? _attentionStartedAt;
  int _extraMinutes = 0;
  bool _isExtending = false;
  bool _warningShown = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.detail.status;
    if (_normalizeStatus(_currentStatus) == AppointmentStatuses.inAttention &&
        widget.detail.attentionStartedAt != null) {
      _attentionStartedAt = widget.detail.attentionStartedAt;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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

  Color _statusBackgroundColor(BuildContext context, String status) {
    final normalized = _normalizeStatus(status);
    final scheme = Theme.of(context).colorScheme;

    if (normalized == AppointmentStatuses.attended) {
      return scheme.secondaryContainer.withValues(alpha: 0.5);
    }

    if (normalized == AppointmentStatuses.absent ||
        normalized == AppointmentStatuses.canceled) {
      return scheme.error.withOpacity(0.14);
    }

    if (normalized == AppointmentStatuses.calling) {
      return scheme.primary.withOpacity(0.14);
    }

    if (normalized == AppointmentStatuses.inAttention ||
        normalized == 'atendiendo') {
      return scheme.secondaryContainer.withValues(alpha: 0.5);
    }

    return scheme.outline.withOpacity(0.16);
  }

  Color _statusForegroundColor(BuildContext context, String status) {
    final normalized = _normalizeStatus(status);
    final scheme = Theme.of(context).colorScheme;

    if (normalized == AppointmentStatuses.attended) {
      return scheme.onSecondaryContainer;
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
      return scheme.onSecondaryContainer;
    }

    return scheme.onSurface;
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final foreground = _statusForegroundColor(context, status);

    return Chip(
      backgroundColor: _statusBackgroundColor(context, status),
      side: BorderSide(color: foreground.withOpacity(0.35)),
      label: Text(
        _statusLabel(status),
        style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _updateStatus(
    String status, {
    bool closeOnSuccess = true,
  }) async {
    if (_updatingStatus != null) return;

    setState(() => _updatingStatus = status);

    try {
      final successMessage = await _api.updateAppointmentStatus(
        appointmentId: widget.detail.id,
        status: status,
        isGuest: widget.detail.isGuest,
      );

      if (!mounted) return;
      setState(() {
        _currentStatus = status;
        _updatingStatus = null;
      });

      if (closeOnSuccess) {
        Navigator.of(
          context,
        ).pop({'status': status, 'message': successMessage});
      } else {
        await AppToast.showSuccess(
          context,
          message: successMessage ?? 'Turno cambiado a ${_statusLabel(status)}',
        );
      }
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      await AppToast.showError(context, message: message);
      setState(() => _updatingStatus = null);
    }
  }

  void _startTimer() {
    _warningShown = false;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_remainingSeconds == 60 && !_warningShown) {
        _warningShown = true;
        _showWarningDialog();
      }
    });
  }

  Future<void> _showWarningDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isExtending = false;
        bool isAttending = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('⏱ Tiempo por agotarse'),
            content: const Text(
              'Queda 1 minuto de atención. ¿Desea agregar 15 minutos más o marcar el turno como atendido?',
            ),
            actions: [
              TextButton.icon(
                icon: isAttending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Atendido'),
                onPressed: (isExtending || isAttending)
                    ? null
                    : () async {
                        setDialogState(() => isAttending = true);
                        Navigator.of(dialogContext).pop();
                        await _updateStatus(AppointmentStatuses.attended);
                      },
              ),
              ElevatedButton.icon(
                icon: isExtending
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      )
                    : const Icon(Icons.add, size: 18),
                label: const Text('+15 min'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  elevation: 0,
                ),
                onPressed: (isExtending || isAttending)
                    ? null
                    : () async {
                        setDialogState(() => isExtending = true);
                        Navigator.of(dialogContext).pop();
                        _warningShown = false;
                        await _extendTime();
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  int get _remainingSeconds {
    if (_attentionStartedAt == null) return 0;
    final elapsed = DateTime.now().difference(_attentionStartedAt!).inSeconds;
    final total = (15 + _extraMinutes * 15) * 60;
    return (total - elapsed).clamp(0, total);
  }

  Future<void> _startAttention() async {
    setState(() => _updatingStatus = AppointmentStatuses.inAttention);
    try {
      await _api.startAttention(
        appointmentId: widget.detail.id,
        isGuest: widget.detail.isGuest,
      );
      if (!mounted) return;
      setState(() {
        _currentStatus = AppointmentStatuses.inAttention;
        // Usar hora Colombia actual como referencia local para el countdown.
        // Evita desfases si el backend retorna UTC o zona distinta.
        _attentionStartedAt = DateTime.now();
        _updatingStatus = null;
      });
      _startTimer();
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      await AppToast.showError(context, message: message);
      setState(() => _updatingStatus = null);
    }
  }

  Future<void> _extendTime() async {
    if (_isExtending) return;
    setState(() => _isExtending = true);
    try {
      await _api.extendTime(
        appointmentId: widget.detail.id,
        isGuest: widget.detail.isGuest,
      );
      if (!mounted) return;
      setState(() {
        _extraMinutes++;
        _isExtending = false;
      });
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      await AppToast.showError(context, message: message);
      setState(() => _isExtending = false);
    }
  }

  Widget _buildAttentionTimer() {
    final scheme = Theme.of(context).colorScheme;
    final remaining = _remainingSeconds;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    final isWarning = remaining < 120;
    final color = isWarning ? scheme.error : scheme.secondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  remaining == 0 ? 'Tiempo agotado' : 'Tiempo en atención',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isExtending ? null : _extendTime,
            icon: _isExtending
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isWarning ? scheme.onError : scheme.onSecondary,
                    ),
                  )
                : const Icon(Icons.add, size: 18),
            label: const Text('+15 min'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: isWarning
                  ? scheme.onError
                  : scheme.onSecondary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCallModal() async {
    if (_updatingStatus != null) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isUpdating = _updatingStatus == AppointmentStatuses.inAttention;

        return AlertDialog(
          title: const Text('Gestionar llamado'),
          content: const Text(
            'Se esta llamando al estudiante cual se le asignó el turno. Cuando el estudiante se encuentre en atención, presiona el botón "En atención".',
          ),
          actions: [
            TextButton(
              onPressed: isUpdating
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isUpdating
                  ? null
                  : () {
                      Navigator.of(dialogContext).pop();
                      _startAttention();
                    },
              child: isUpdating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('En atención'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleCallFlow() async {
    if (_updatingStatus != null) return;

    if (_currentStatus != AppointmentStatuses.calling) {
      await _updateStatus(AppointmentStatuses.calling, closeOnSuccess: false);
      if (!mounted) return;
      if (_currentStatus != AppointmentStatuses.calling) return;
    }

    await _showCallModal();
  }

  Widget _infoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final normalizedStatus = _normalizeStatus(_currentStatus);
    final canFinalizeAttention =
        normalizedStatus == AppointmentStatuses.inAttention ||
        normalizedStatus == 'atendiendo';
    final canMarkAbsent =
        canFinalizeAttention || normalizedStatus == AppointmentStatuses.calling;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del turno')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
                vertical: 16,
              ),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                detail.turnNumber,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _buildStatusChip(context, _currentStatus),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed:
                                _updatingStatus == null &&
                                    _currentStatus !=
                                        AppointmentStatuses.inAttention
                                ? _handleCallFlow
                                : null,
                            icon:
                                _updatingStatus ==
                                        AppointmentStatuses.calling ||
                                    _updatingStatus ==
                                        AppointmentStatuses.inAttention
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.record_voice_over_outlined),
                            label: const Text('Llamar turno'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _infoRow(
                          label: 'Categoría',
                          value: _titleCase(detail.category),
                        ),
                        _infoRow(
                          label: 'Contexto',
                          value: _titleCase(detail.context),
                        ),
                        _infoRow(label: 'Sede', value: _titleCase(detail.sede)),
                        _infoRow(
                          label: 'Fecha',
                          value: AppDateFormatter.dateShort(detail.scheduledAt),
                        ),
                        _infoRow(
                          label: 'Hora',
                          value: AppDateFormatter.time12FromDateTime(
                            detail.scheduledAt,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_attentionStartedAt != null) ...[
                  _buildAttentionTimer(),
                  const SizedBox(height: 10),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información del estudiante',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _infoRow(
                          label: 'Nombre',
                          value: detail.student.fullName,
                        ),
                        _infoRow(label: 'Correo', value: detail.student.email),
                        _infoRow(
                          label: 'Programa',
                          value: _titleCase(detail.student.academicProgram),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SecretaryStatusActionButton(
                  label: 'Atendido',
                  icon: Icons.check_circle_outline,
                  loading: _updatingStatus == AppointmentStatuses.attended,
                  onPressed: _updatingStatus == null && canFinalizeAttention
                      ? () => _updateStatus(AppointmentStatuses.attended)
                      : null,
                  variant: SecretaryStatusActionVariant.successFilled,
                ),
                const SizedBox(height: 8),
                SecretaryStatusActionButton(
                  label: 'No asistió',
                  icon: Icons.person_off_outlined,
                  loading: _updatingStatus == AppointmentStatuses.absent,
                  onPressed: _updatingStatus == null && canMarkAbsent
                      ? () => _updateStatus(AppointmentStatuses.absent)
                      : null,
                  variant: SecretaryStatusActionVariant.dangerOutlined,
                ),
                const SizedBox(height: 8),
                SecretaryStatusActionButton(
                  label: 'Cancelada',
                  icon: Icons.cancel_outlined,
                  loading: _updatingStatus == AppointmentStatuses.canceled,
                  onPressed: _updatingStatus == null
                      ? () => _updateStatus(AppointmentStatuses.canceled)
                      : null,
                  variant: SecretaryStatusActionVariant.dangerOutlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
