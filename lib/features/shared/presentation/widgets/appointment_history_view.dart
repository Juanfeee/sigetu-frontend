import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sigetu/core/constants/appointment_statuses.dart';
import 'package:sigetu/core/realtime/appointments_realtime_service.dart';
import 'package:sigetu/core/utils/responsive.dart';
import 'package:sigetu/features/secretary/domain/secretary_appointment.dart';

typedef FetchHistoryCallback = Future<List<SecretaryAppointment>> Function();

class AppointmentHistoryView extends StatefulWidget {
  const AppointmentHistoryView({
    super.key,
    required this.title,
    required this.fetchHistory,
    this.emptyMessage = 'No hay citas en el historial',
    this.autoRefreshSeconds,
  });

  final String title;
  final FetchHistoryCallback fetchHistory;
  final String emptyMessage;
  final int? autoRefreshSeconds;

  @override
  State<AppointmentHistoryView> createState() => _AppointmentHistoryViewState();
}

class _AppointmentHistoryViewState extends State<AppointmentHistoryView>
    with WidgetsBindingObserver {
  final _realtime = AppointmentsRealtimeService();
  bool _isLoading = false;
  String? _errorMessage;
  List<SecretaryAppointment> _history = [];
  StreamSubscription<void>? _realtimeSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHistory();
    _connectRealtime();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    super.dispose();
  }

  void _connectRealtime() {
    _realtime.connect();

    _realtimeSubscription = _realtime.updates.listen((_) {
      if (!mounted || _isLoading) return;
      _loadHistory();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadHistory();
    }
  }

  void _startAutoRefresh() {
    // Auto-refresco desactivado por defecto
    // Si se necesita, pasar autoRefreshSeconds: 30 (o el valor deseado)
    final seconds = widget.autoRefreshSeconds;
    if (seconds == null || seconds <= 0) return;

    _refreshTimer = Timer.periodic(Duration(seconds: seconds), (_) {
      if (mounted && !_isLoading) {
        _loadHistory();
      }
    });
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
    final normalized = status.trim().toLowerCase();
    switch (normalized) {
      case AppointmentStatuses.attended:
        return 'Atendido';
      case AppointmentStatuses.absent:
        return 'No asistió';
      case AppointmentStatuses.canceled:
        return 'Cancelado';
      default:
        return _titleCase(status);
    }
  }

  Color _statusColor(BuildContext context, String status) {
    final normalized = status.trim().toLowerCase();
    final scheme = Theme.of(context).colorScheme;

    if (normalized == AppointmentStatuses.attended) {
      return scheme.secondary;
    }

    if (normalized == AppointmentStatuses.absent ||
        normalized == AppointmentStatuses.canceled) {
      return scheme.error;
    }

    return scheme.onSurface;
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

  Future<void> _loadHistory() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final history = await widget.fetchHistory();

      if (!mounted) return;
      setState(() {
        _history = history;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final hPad = Responsive.horizontalPadding(context);

            if (_errorMessage != null) {
              return ListView(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                children: [
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadHistory,
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }

            if (_history.isEmpty) {
              return ListView(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      widget.emptyMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final appointment = _history[index];
                return _buildAppointmentCard(context, appointment);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    SecretaryAppointment appointment,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final infoIconColor = scheme.onSurface.withValues(alpha: 0.58);
    final primaryTone = scheme.primary;
    final titleTone = scheme.onSurface;
    final detailText = appointment.context.trim().isNotEmpty
        ? _titleCase(appointment.context)
        : _titleCase(appointment.category);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
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
                    _buildStatusChip(context, appointment.status),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: infoIconColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appointment.studentName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if (appointment.studentProgramaAcademico != null &&
                    appointment.studentProgramaAcademico!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 16,
                        color: infoIconColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _titleCase(appointment.studentProgramaAcademico!),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 16,
                      color: infoIconColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _titleCase(appointment.category),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: infoIconColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        detailText,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: infoIconColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        DateFormat(
                          'dd/MM/yyyy - HH:mm',
                        ).format(appointment.scheduledAt),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
