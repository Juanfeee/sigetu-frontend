import 'package:flutter/material.dart';
import 'package:sigetu/features/student_dashboard/domain/student_turn.dart';

class StudentTurnCard extends StatelessWidget {
  const StudentTurnCard({
    super.key,
    required this.turn,
    required this.statusLabel,
    required this.statusColor,
    required this.formattedDate,
    required this.formattedTime,
    required this.canEdit,
    required this.isUpdating,
    required this.onReprogram,
    required this.onCancel,
  });

  final StudentTurn turn;
  final String statusLabel;
  final Color statusColor;
  final String formattedDate;
  final String formattedTime;
  final bool canEdit;
  final bool isUpdating;
  final VoidCallback onReprogram;
  final VoidCallback onCancel;

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final infoIconColor = scheme.onSurface.withValues(alpha: 0.58);
    final primaryTone = scheme.primary;
    final titleTone = scheme.onSurface;
    final detailText = turn.context.trim().isNotEmpty
        ? _titleCase(turn.context)
        : _titleCase(turn.category);

    return Container(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: titleTone,
                      ),
                      children: [
                        const TextSpan(text: 'Turno '),
                        TextSpan(
                          text: turn.turnNumber,
                          style: TextStyle(
                            color: primaryTone,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.location_on_outlined,
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
                        _titleCase(turn.sede),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detailText,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.86),
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
                        formattedDate,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w400),
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
                        formattedTime,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (canEdit) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ActionOutlineButton(
                      label: 'Reprogramar',
                      icon: isUpdating ? null : Icons.sync_rounded,
                      color: scheme.primary,
                      filled: true,
                      onPressed: isUpdating ? null : onReprogram,
                      trailing: isUpdating
                          ? SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionOutlineButton(
                      label: 'Cancelar',
                      icon: Icons.close,
                      color: scheme.error,
                      filled: false,
                      onPressed: isUpdating ? null : onCancel,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionOutlineButton extends StatelessWidget {
  const _ActionOutlineButton({
    required this.label,
    required this.color,
    required this.onPressed,
    required this.filled,
    this.icon,
    this.trailing,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool filled;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: SizedBox(
        height: 48,
        child: filled
            ? ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: scheme.onPrimary,
            disabledBackgroundColor: color.withValues(alpha: 0.45),
            disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: scheme.onPrimary),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            ],
          ),
        )
            : OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.2),
            foregroundColor: color,
            backgroundColor: scheme.surface.withValues(alpha: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
