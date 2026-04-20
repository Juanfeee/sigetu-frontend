import 'package:flutter/material.dart';

class AdminToggleItem {
  const AdminToggleItem({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
}

class AdminToggleCard extends StatelessWidget {
  const AdminToggleCard({
    super.key,
    required this.items,
  });

  final List<AdminToggleItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 1.5 : 4,
      shadowColor: scheme.shadow.withValues(alpha: isDark ? 0.25 : 0.12),
      surfaceTintColor: scheme.surface.withValues(alpha: 0),
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            for (final item in items)
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(item.title),
                value: item.value,
                onChanged: item.onChanged,
              ),
          ],
        ),
      ),
    );
  }
}
