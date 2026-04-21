import 'package:flutter/material.dart';

class AdminFormActionButtons extends StatelessWidget {
  const AdminFormActionButtons({
    super.key,
    required this.primaryLabel,
    required this.primaryOnPressed,
    required this.secondaryLabel,
    required this.secondaryOnPressed,
    this.isPrimaryLoading = false,
  });

  final String primaryLabel;
  final VoidCallback? primaryOnPressed;
  final String secondaryLabel;
  final VoidCallback? secondaryOnPressed;
  final bool isPrimaryLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: isPrimaryLoading ? null : primaryOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isPrimaryLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimary,
                  ),
                )
              : Text(
                  primaryLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: isPrimaryLoading ? null : secondaryOnPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            foregroundColor: scheme.primary,
          ),
          child: Text(
            secondaryLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
