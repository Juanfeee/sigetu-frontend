import 'package:flutter/material.dart';

import 'screens/admin_home_shell.dart';
import 'screens/admin_programs_screen.dart';
import 'screens/admin_sedes_screen.dart';
import 'screens/admin_users_screen.dart';

class AdminRoutes {
  static const home = '/admin-home';
  static const programs = '/admin-programs';
  static const sedes = '/admin-sedes';
  static const users = '/admin-users';

  static Map<String, WidgetBuilder> routes = {
    home: (_) => const AdminHomeShell(),
    programs: (_) => const AdminProgramsScreen(),
    sedes: (_) => const AdminSedesScreen(),
    users: (_) => const AdminUsersScreen(),
  };
}