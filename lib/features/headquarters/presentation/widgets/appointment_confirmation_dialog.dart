import 'package:flutter/material.dart';

class AppointmentConfirmationDialog extends StatelessWidget {
  const AppointmentConfirmationDialog({
    super.key,
    required this.headquarter,
    required this.area,
    required this.attentionType,
    required this.formattedDate,
    required this.formattedTime,
  });

  final String headquarter;
  final String area;
  final String attentionType;
  final String formattedDate;
  final String formattedTime;

  static Future<bool> show({
    required BuildContext context,
    String headquarter = 'Sede Administrativa',
    required String area,
    required String attentionType,
    required String formattedDate,
    required String formattedTime,
  }) async {
    final shouldSchedule = await showDialog<bool>(
      context: context,
      builder: (_) => AppointmentConfirmationDialog(
        headquarter: headquarter,
        area: area,
        attentionType: attentionType,
        formattedDate: formattedDate,
        formattedTime: formattedTime,
      ),
    );

    return shouldSchedule ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿La información es correcta?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Revisa los datos antes de agendar la cita.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            _ConfirmationInfoTile(
              label: 'Sede',
              value: headquarter,
            ),
            const SizedBox(height: 10),
            _ConfirmationInfoTile(
              label: 'Área',
              value: area,
            ),
            const SizedBox(height: 10),
            _ConfirmationInfoTile(
              label: 'Tipo de atención',
              value: attentionType,
            ),
            const SizedBox(height: 12),
            Divider(color: scheme.outline.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: 12),
            _ConfirmationInfoTile(
              label: 'Fecha',
              value: formattedDate,
            ),
            const SizedBox(height: 10),
            _ConfirmationInfoTile(
              label: 'Hora',
              value: formattedTime,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Agendar cita'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationInfoTile extends StatelessWidget {
  const _ConfirmationInfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
