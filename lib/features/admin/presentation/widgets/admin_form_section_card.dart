import 'package:flutter/material.dart';

class AdminFormSectionCard extends StatelessWidget {
  const AdminFormSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardBackground = isDark ? scheme.surfaceContainerLow : scheme.surface;
    final inputBackground = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.36)
        : scheme.surfaceContainerLowest;

    return Card(
      elevation: isDark ? 1.5 : 4,
      shadowColor: scheme.shadow.withValues(alpha: isDark ? 0.25 : 0.12),
      surfaceTintColor: scheme.surface.withValues(alpha: 0),
      color: cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: inputBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
