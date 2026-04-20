import 'package:flutter/material.dart';

class AdminDialogActionButtons extends StatelessWidget {
  const AdminDialogActionButtons({
    super.key,
    required this.confirmLabel,
    required this.onConfirm,
    required this.cancelLabel,
    required this.onCancel,
    this.isConfirmLoading = false,
  });

  final String confirmLabel;
  final VoidCallback? onConfirm;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final bool isConfirmLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: isConfirmLoading ? null : onCancel,
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: isConfirmLoading ? null : onConfirm,
            child: isConfirmLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  )
                : Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}
