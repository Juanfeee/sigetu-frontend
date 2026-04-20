import 'package:flutter/material.dart';
import 'package:sigetu/core/auth/auth_session.dart';
import 'package:sigetu/core/utils/responsive.dart';
import 'package:sigetu/core/widgets/app_toast.dart';
import 'package:sigetu/features/auth/data/auth_api.dart';
import 'package:sigetu/features/auth/domain/user_register.dart';
import 'package:sigetu/features/auth/presentation/auth_routes.dart';
import 'package:sigetu/features/shared/data/academic_programs_api.dart';
import 'package:sigetu/features/shared/domain/academic_program.dart';
import 'login_screen.dart' show BubblesPainter;
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static final RegExp _institutionalEmailRegex = RegExp(
    r'^[^@\s]+@uniautonoma\.edu\.co$',
    caseSensitive: false,
  );

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  final _authApi = AuthApi();
  final _programsApi = AcademicProgramsApi();
  bool _isLoading = false;
  bool _isLoadingAcademicPrograms = true;
  String? _academicProgramsError;
  List<AcademicProgram> _academicPrograms = [];
  int? _academicProgramId;

  @override
  void initState() {
    super.initState();
    _loadAcademicPrograms();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  String _mapErrorMessage(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }
    return message;
  }

  Future<void> _loadAcademicPrograms() async {
    setState(() {
      _isLoadingAcademicPrograms = true;
      _academicProgramsError = null;
    });

    try {
      final programs = await _programsApi.fetchPrograms(onlyActive: true);
      if (!mounted) return;
      setState(() {
        _academicPrograms = programs;
        _academicProgramId = null;
        _isLoadingAcademicPrograms = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _academicProgramsError = _mapErrorMessage(error);
        _academicPrograms = [];
        _academicProgramId = null;
        _isLoadingAcademicPrograms = false;
      });
    }
  }

  Future<void> _showRequestMessage(String message, {required bool isError}) {
    if (isError) {
      return AppToast.showError(context, message: message);
    }
    return AppToast.showSuccess(context, message: message);
  }

  Future<void> _submitRegister() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final user = UserRegister(
      email: _emailController.text.trim(),
      fullName: _nameController.text.trim(),
      password: _passwordController.text,
      academicProgramId: _academicProgramId!,
    );

    try {
      // Si el usuario venía de modo invitado, transferir sus citas al nuevo usuario
      final guestDeviceId = AuthSession.isGuest ? AuthSession.deviceId : null;
      final successMessage = await _authApi.register(
        user,
        deviceId: guestDeviceId,
      );
      if (!mounted) return;
      AuthSession.clear();
      await _showRequestMessage(
        successMessage ?? 'Registro exitoso',
        isError: false,
      );
      Navigator.pushReplacementNamed(context, AuthRoutes.login);
    } catch (error) {
      if (!mounted) return;
      await _showRequestMessage(_mapErrorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = !Responsive.isMobile(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgColor,
                  Color.lerp(bgColor, scheme.primary, 0.08)!,
                  bgColor,
                ],
              ),
            ),
          ),
          CustomPaint(
            painter: BubblesPainter(
              primaryColor: scheme.primary,
              shadowColor: scheme.shadow,
              highlightColor: scheme.onPrimary,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 440 : double.infinity,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Crear cuenta',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ingresa con tu correo institucional',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.shadow.withValues(alpha: 0.25),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.06),
                              blurRadius: 60,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Form(
                          key: _formKey,
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AuthTextField(
                                  label: 'Nombre completo',
                                  icon: Icons.person_outline,
                                  controller: _nameController,
                                  focusNode: _nameFocusNode,
                                  keyboardType: TextInputType.name,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                  onEditingComplete: () => FocusScope.of(
                                    context,
                                  ).requestFocus(_emailFocusNode),
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
                                  focusNode: _emailFocusNode,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  onEditingComplete: () => FocusScope.of(
                                    context,
                                  ).requestFocus(_passwordFocusNode),
                                  validator: (value) {
                                    final email = value?.trim() ?? '';
                                    if (email.isEmpty) {
                                      return 'Ingrese su correo';
                                    }
                                    if (!_institutionalEmailRegex.hasMatch(
                                      email,
                                    )) {
                                      return 'Use su correo @uniautonoma.edu.co';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Semantics(
                                  label: 'Programa académico',
                                  child: DropdownButtonFormField<int>(
                                    initialValue: _academicProgramId,
                                    decoration: InputDecoration(
                                      labelText: 'Programa académico',
                                      prefixIcon: const Icon(
                                        Icons.school_outlined,
                                      ),
                                      suffixIcon: _isLoadingAcademicPrograms
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            )
                                          : _academicProgramsError != null
                                          ? IconButton(
                                              tooltip: 'Reintentar',
                                              icon: const Icon(Icons.refresh),
                                              onPressed: _loadAcademicPrograms,
                                            )
                                          : null,
                                    ),
                                    items: _academicPrograms
                                        .map(
                                          (program) => DropdownMenuItem<int>(
                                            value: program.id,
                                            child: Text(program.nombre),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: _isLoading || _isLoadingAcademicPrograms
                                        ? null
                                        : (value) => setState(
                                            () => _academicProgramId = value,
                                          ),
                                    validator: (value) {
                                      if (_isLoadingAcademicPrograms) {
                                        return 'Cargando programas académicos';
                                      }
                                      if (value == null) {
                                        return 'Seleccione su programa académico';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                if (_academicProgramsError != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _academicProgramsError!,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: scheme.error,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                AuthTextField(
                                  label: 'Contraseña',
                                  icon: Icons.lock_outline,
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: true,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  onEditingComplete: () => FocusScope.of(
                                    context,
                                  ).requestFocus(_confirmPasswordFocusNode),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingrese su contraseña';
                                    }
                                    if (value.length < 8) {
                                      return 'Mínimo 8 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                AuthTextField(
                                  label: 'Confirmar contraseña',
                                  icon: Icons.lock_outline,
                                  controller: _confirmPasswordController,
                                  focusNode: _confirmPasswordFocusNode,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  onEditingComplete: _submitRegister,
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
                                  isLoading: _isLoading,
                                  onPressed: _submitRegister,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pushNamed(
                                context,
                                AuthRoutes.login,
                              ),
                        child: Text.rich(
                          TextSpan(
                            text: '¿Ya tienes cuenta? ',
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                            children: [
                              TextSpan(
                                text: 'Inicia sesión',
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }
}
