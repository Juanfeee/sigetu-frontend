import 'package:flutter/material.dart';

class AdminPageContainer extends StatelessWidget {
  const AdminPageContainer({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.appBarBackgroundColor,
    this.appBarForegroundColor,
    this.backgroundColor,
    this.centerTitle = false,
  });

  static const Color _darkBackground = Color(0xFF0F172A);
  static const Color _lightBackground = Color(0xFFF4F8FF);

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Color? appBarBackgroundColor;
  final Color? appBarForegroundColor;
  final Color? backgroundColor;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBackground =
        backgroundColor ??
      (isDark ? _darkBackground : _lightBackground);

    final resolvedAppBarBackground = appBarBackgroundColor ?? scheme.primary;
    final resolvedAppBarForeground = appBarForegroundColor ?? scheme.onPrimary;

    return Scaffold(
      backgroundColor: resolvedBackground,
      appBar: AppBar(
        backgroundColor: resolvedAppBarBackground,
        foregroundColor: resolvedAppBarForeground,
        elevation: 0,
        centerTitle: centerTitle,
        title: Text(
          title,
          style: TextStyle(
            color: resolvedAppBarForeground,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: actions,
      ),
      body: Container(
        color: resolvedBackground,
        child: body,
      ),
    );
  }
}
