import 'package:flutter/material.dart';
import 'screens/student_home_shell.dart';
import 'screens/seleccionar_sede_screen.dart';
class StudentDashboardRoutes {
  static const dashboard = '/student-dashboard';
  static const seleccionarSede = '/seleccionar-sede';

  static Map<String, WidgetBuilder> routes = {
    dashboard: (_) => const StudentHomeShell(),
    seleccionarSede: (_) => const SeleccionarSedeScreen(),
  };
}