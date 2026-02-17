import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

class AuthRoutes {
  static const login = '/login';
  static const register = '/register';

  static Map<String, WidgetBuilder> routes = {
    login: (_) => LoginScreen(),
    register: (_) => RegisterScreen(),
  };
}
