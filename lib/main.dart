import 'package:flutter/material.dart';
import 'package:sigetu/features/student_dashboard/presentation/student_dashboard_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_routes.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIGETU - UNIAUTÓNOMA',

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      initialRoute: AuthRoutes.login,

      routes: {
        ...AuthRoutes.routes,
        ...StudentDashboardRoutes.routes,
      },
    );
  }
}
  