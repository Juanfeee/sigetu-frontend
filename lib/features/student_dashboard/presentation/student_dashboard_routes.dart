import 'package:flutter/material.dart';
import 'screens/student_dashboard_screen.dart';

class StudentDashboardRoutes {
  static const dashboard = '/student-dashboard';

  static Map<String, WidgetBuilder> routes = {
    dashboard: (_) => const StudentDashboardScreen(),
  };
}
