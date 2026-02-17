import 'package:flutter/material.dart';
import 'package:sigetu/features/auth/presentation/auth_routes.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import 'package:sigetu/features/student_dashboard/presentation/student_dashboard_routes.dart';


class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              //centrar todo el contenido
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlutterLogo(size: 100),
                SizedBox(height: 14),
                Text(
                  'SIGETU - UNIAUTÓNOMA',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Sistema de Gestión de Turnos',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 32),
                AuthTextField(
                  label: 'Correo institucional',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese su correo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Contraseña',
                  icon: Icons.lock_outline,
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese su contraseña';
                    }
                    return null;
                  },
                ),
                // Olvidaste tu contraseña
                TextButton(
                  onPressed: () {},
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
                const SizedBox(height: 22),
                AuthButton(
                  text: 'Ingresar',
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pushReplacementNamed(
                        context,
                        StudentDashboardRoutes.dashboard,
                      );
                    }
                  },
                ),

                // No tienes cuenta? Registrate
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AuthRoutes.register);
                  },
                  child: Text.rich(
                    TextSpan(
                      text: '¿No tienes cuenta? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: 'Regístrate',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
