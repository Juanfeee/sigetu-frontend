import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigetu/core/auth/auth_session.dart';
import 'package:sigetu/core/constants/appointment_statuses.dart';
import 'package:sigetu/core/realtime/appointments_realtime_service.dart';
import 'package:sigetu/core/utils/app_date_formatter.dart';
import 'package:sigetu/core/utils/responsive.dart';
import 'package:sigetu/core/widgets/app_toast.dart';
import 'package:sigetu/features/student_dashboard/data/student_turns_api.dart';
import 'package:sigetu/features/student_dashboard/domain/student_turn.dart';
import 'package:sigetu/features/student_dashboard/presentation/screens/reprogram_cita_screen.dart';
import 'package:sigetu/features/student_dashboard/presentation/widgets/student_turn_card.dart';

class TurnosScreen extends StatefulWidget {
  const TurnosScreen({super.key});

  @override
  State<TurnosScreen> createState() => _TurnosScreenState();
}

class _TurnosScreenState extends State<TurnosScreen> {
  final _api = StudentTurnsApi();
  final _realtime = AppointmentsRealtimeService();

  bool _isLoading = true;
  bool _isFetching = false;
  String? _errorMessage;
  List<StudentTurn> _turns = [];
  final Set<int> _notifiedCallingTurnIds = <int>{};
  int? _updatingTurnId;
  bool _showHistory = false;
  StreamSubscription<void>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _loadTurns();
    _realtime.connect();
    _realtimeSubscription = _realtime.updates.listen((_) {
      if (!mounted) return;
      _loadTurns(showLoader: false);
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    unawaited(_realtime.dispose());
    super.dispose();
  }

  Future<void> _loadTurns({bool showLoader = true}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<StudentTurn> turns;
      if (AuthSession.isGuest && AuthSession.deviceId != null) {
        // Invitado: obtener citas actuales o historial por device_id
        turns = _showHistory
            ? await _api.fetchGuestHistory(AuthSession.deviceId!)
            : await _api.fetchGuestTurns(AuthSession.deviceId!);
      } else {
        turns = _showHistory
            ? await _api.fetchMyTurnsHistory()
            : await _api.fetchMyTurns();
      }

      _handleCallingSound(turns);

      if (!mounted) return;
      setState(() {
        _turns = turns;
        if (!showLoader) {
          _errorMessage = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      _isFetching = false;
      if (mounted) {
        setState(() {
          if (showLoader) {
            _isLoading = false;
          }
        });
      }
    }
  }

  void _handleCallingSound(List<StudentTurn> turns) {
    if (_showHistory) return;

    final callingIds = turns
        .where(
          (turn) =>
              turn.status.trim().toLowerCase() == AppointmentStatuses.calling,
        )
        .map((turn) => turn.id)
        .toSet();

    final newCallingIds = callingIds.difference(_notifiedCallingTurnIds);

    if (newCallingIds.isNotEmpty) {
      unawaited(SystemSound.play(SystemSoundType.alert));
      _notifiedCallingTurnIds.addAll(newCallingIds);
    }

    _notifiedCallingTurnIds.removeWhere((id) => !callingIds.contains(id));
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

  bool _canEditTurn(StudentTurn turn) {
    final normalized = turn.status.trim().toLowerCase();
    return normalized == AppointmentStatuses.pending;
  }

  Future<void> _reprogramTurn(StudentTurn turn) async {
    if (!_canEditTurn(turn)) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ReprogramarCitaScreen(turn: turn)),
    );

    if (result == true) {
      await _loadTurns();
    }
  }

  Future<void> _cancelTurn(StudentTurn turn) async {
    if (!_canEditTurn(turn)) return;

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancelar turno'),
          content: Text('¿Deseas cancelar el turno ${turn.turnNumber}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldCancel != true) return;

    setState(() => _updatingTurnId = turn.id);

    try {
      final successMessage = await _api.cancelAppointment(
        appointmentId: turn.id,
      );
      if (!mounted) return;
      await AppToast.showSuccess(
        context,
        message: successMessage ?? 'Turno cancelado correctamente',
      );
      await _loadTurns();
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      await AppToast.showError(context, message: message);
    } finally {
      if (mounted) {
        setState(() => _updatingTurnId = null);
      }
    }
  }

  Color _statusColor(String status, ColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case AppointmentStatuses.pending:
        return colorScheme.tertiary;
      case AppointmentStatuses.calling:
        return colorScheme.primary;
      case AppointmentStatuses.inAttention:
        return colorScheme.secondary;
      case AppointmentStatuses.attended:
      case AppointmentStatuses.finished:
        return colorScheme.secondary;
      case AppointmentStatuses.absent:
        return colorScheme.outline;
      case AppointmentStatuses.canceled:
        return colorScheme.error;
      default:
        return colorScheme.primary;
    }
  }

  Future<void> _changeViewMode(bool showHistory) async {
    if (_showHistory == showHistory) return;
    setState(() => _showHistory = showHistory);
    await _loadTurns();
  }

  Widget _buildViewModeToggle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isHistory = _showHistory;

    return SizedBox(
      width: 220,
      height: 46,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final selectorWidth = (constraints.maxWidth - 8) / 2;

          return Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.secondary],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: isHistory
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: selectorWidth,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: scheme.surface.withValues(alpha: 0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => _changeViewMode(false),
                          child: Center(
                            child: Text(
                              'Actuales',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isHistory
                                        ? scheme.onPrimary
                                        : scheme.primary,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Material(
                        color: scheme.surface.withValues(alpha: 0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => _changeViewMode(true),
                          child: Center(
                            child: Text(
                              'Historial',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isHistory
                                        ? scheme.primary
                                        : scheme.onPrimary,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Turnos'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildViewModeToggle(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTurns,
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_errorMessage != null) {
              return ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                  vertical: 20,
                ),
                children: [
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadTurns,
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }

            if (_turns.isEmpty) {
              return ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                  vertical: 20,
                ),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      _showHistory
                          ? 'No tienes turnos en historial'
                          : 'No tienes turnos actuales',
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
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
                vertical: 16,
              ),
              itemCount: _turns.length,
              itemBuilder: (context, index) {
                final turn = _turns[index];
                final statusColor = _statusColor(
                  turn.status,
                  Theme.of(context).colorScheme,
                );
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: StudentTurnCard(
                      turn: turn,
                      statusLabel: _titleCase(turn.status),
                      statusColor: statusColor,
                      formattedDate: AppDateFormatter.dateShort(
                        turn.scheduledAt,
                      ),
                      formattedTime: AppDateFormatter.time12FromDateTime(
                        turn.scheduledAt,
                      ),
                      canEdit: _canEditTurn(turn),
                      isUpdating: _updatingTurnId == turn.id,
                      onReprogram: () => _reprogramTurn(turn),
                      onCancel: () => _cancelTurn(turn),
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
