import 'package:flutter/material.dart';
import 'package:sigetu/features/auth/presentation/auth_routes.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      48, // padding aproximado
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FlutterLogo(size: 100),
                      const SizedBox(height: 14),

                      const Text(
                        'Crear Cuenta',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 32),

                      AuthTextField(
                        label: 'Nombre completo',
                        icon: Icons.person_outline,
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese su nombre';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

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
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese su contraseña';
                          }
                          if (value.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      AuthTextField(
                        label: 'Confirmar contraseña',
                        icon: Icons.lock_outline,
                        controller: _confirmPasswordController,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirme su contraseña';
                          }
                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      AuthButton(
                        text: 'Registrarse',
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Luego conectamos el UseCase
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AuthRoutes.login);
                        },
                        child: Text.rich(
                          TextSpan(
                            text: '¿Ya tienes cuenta? ',
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Inicia sesión',
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
          ),
        ),
      ),
    );
  }
}
