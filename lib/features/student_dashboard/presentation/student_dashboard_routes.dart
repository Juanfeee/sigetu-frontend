import 'package:flutter/material.dart';
import 'screens/student_home_shell.dart';
import '../../headquarters/presentation/screens/seleccionar_sede_screen.dart';
class StudentDashboardRoutes {
  static const dashboard = '/student-dashboard';
  static const turnos = '/student-turnos';
  static const seleccionarSede = '/seleccionar-sede';

  static Map<String, WidgetBuilder> routes = {
    dashboard: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final initialIndex = args is Map<String, dynamic>
          ? (args['initialIndex'] as int? ?? 0)
          : 0;
      return StudentHomeShell(initialIndex: initialIndex);
    },
    turnos: (_) => const StudentHomeShell(initialIndex: 1),
    seleccionarSede: (_) => const SeleccionarSedeScreen(),
  };
}