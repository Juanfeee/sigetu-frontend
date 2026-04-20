import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:sigetu/core/auth/auth_session.dart';
import 'package:sigetu/core/utils/device_id.dart';
import 'package:sigetu/core/utils/responsive.dart';
import 'package:sigetu/core/widgets/app_toast.dart';
import 'package:sigetu/features/admin/presentation/admin_routes.dart';
import 'package:sigetu/features/auth/data/auth_api.dart';
import 'package:sigetu/features/auth/presentation/auth_routes.dart';
import 'package:sigetu/features/secretary/presentation/secretary_routes.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import 'package:sigetu/features/student_dashboard/presentation/student_dashboard_routes.dart';
import 'package:sigetu/core/notifications/fcm_token_sync.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static final RegExp _institutionalEmailRegex = RegExp(
    r'^[^@\s]+@uniautonoma\.edu\.co$',
    caseSensitive: false,
  );

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _mapErrorMessage(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }
    return message;
  }

  String _extractRoleFromToken(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      return '';
    }

    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final data = jsonDecode(payload);

      if (data is Map<String, dynamic>) {
        final role = data['role'] ?? data['rol'];
        if (role is String) {
          return role.toLowerCase();
        }
      }
    } catch (_) {}

    return '';
  }

  Future<void> _showRequestMessage(String message, {required bool isError}) {
    if (isError) {
      return AppToast.showError(context, message: message);
    }
    return AppToast.showSuccess(context, message: message);
  }

  Future<void> _submitLogin() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final loginResponse = await AuthApi().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      AuthSession.setTokens(
        access: loginResponse.accessToken,
        refresh: loginResponse.refreshToken,
      );

      // Sincronizar token FCM tras login exitoso
      await FcmTokenSync.syncFcmToken();
      FcmTokenSync.listenTokenRefresh();

      final role = _extractRoleFromToken(loginResponse.accessToken);
      final isStaffRole = role == 'staff';
      final isAdminRole = role == 'admin';

      await _showRequestMessage(
        loginResponse.message ?? 'Inicio de sesión exitoso',
        isError: false,
      );
      Navigator.pushReplacementNamed(
        context,
        isStaffRole
            ? SecretaryRoutes.home
        : isAdminRole
        ? AdminRoutes.home
            : StudentDashboardRoutes.dashboard,
      );
    } catch (error) {
      if (!mounted) return;
      await _showRequestMessage(_mapErrorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitGuest() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final id = await DeviceId.get();
      final response = await AuthApi().loginGuest(deviceId: id);
      if (!mounted) return;
      AuthSession.setTokens(
        access: response.accessToken,
        guest: true,
        guestDeviceId: id,
      );

      // Sincronizar token FCM para invitados
      await FcmTokenSync.syncFcmToken();
      FcmTokenSync.listenTokenRefresh();

      Navigator.pushReplacementNamed(context, StudentDashboardRoutes.dashboard);
    } catch (error) {
      if (!mounted) return;
      await _showRequestMessage(_mapErrorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          // Fondo degradado
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
          // Esferas decorativas
          CustomPaint(
            painter: BubblesPainter(
              primaryColor: scheme.primary,
              shadowColor: scheme.shadow,
              highlightColor: scheme.onPrimary,
            ),
          ),
          // Contenido
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
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LogoBadge(),
                          const SizedBox(height: 16),
                          Text(
                            'Uniautónoma del Cauca',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sistema de Gestión de Turnos',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Iniciar sesión',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Ingresa con tu correo institucional',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    AuthTextField(
                                      label: 'Correo institucional',
                                      icon: Icons.email_outlined,
                                      controller: _emailController,
                                      focusNode: _emailFocusNode,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
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
                                    AuthTextField(
                                      label: 'Contraseña',
                                      icon: Icons.lock_outline,
                                      controller: _passwordController,
                                      focusNode: _passwordFocusNode,
                                      obscureText: true,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      onEditingComplete: _submitLogin,
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
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: const Text(
                                          '¿Olvidaste tu contraseña?',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    AuthButton(
                                      text: 'Ingresar',
                                      isLoading: _isLoading,
                                      onPressed: _submitLogin,
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
                                    AuthRoutes.register,
                                  ),
                            child: Text.rich(
                              TextSpan(
                                text: '¿No tienes cuenta? ',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Regístrate',
                                    style: TextStyle(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: scheme.outline.withValues(alpha: 0.35),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  'o',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: scheme.outline.withValues(alpha: 0.35),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _submitGuest,
                              icon: const Icon(Icons.person_outline, size: 18),
                              label: const Text('Continuar como invitado'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(
                                  color: scheme.outline.withValues(alpha: 0.5),
                                ),
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
        ],
      ),
    );
  }
}

class BubblesPainter extends CustomPainter {
  final Color primaryColor;
  final Color shadowColor;
  final Color highlightColor;
  const BubblesPainter({
    required this.primaryColor,
    required this.shadowColor,
    required this.highlightColor,
  });

  void _drawSphere(Canvas canvas, Offset center, double radius, Paint base) {
    // Sombra suave
    canvas.drawCircle(
      center + const Offset(4, 8),
      radius,
      Paint()
        ..color = shadowColor.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    // Esfera con gradiente radial
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [
            Color.lerp(
              highlightColor,
              primaryColor,
              0.25,
            )!.withValues(alpha: 0.85),
            Color.lerp(
              primaryColor,
              highlightColor,
              0.1,
            )!.withValues(alpha: 0.55),
            primaryColor.withValues(alpha: 0.18),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    // Borde sutil
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = highlightColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // Reflejo interno
    canvas.drawCircle(
      center + Offset(-radius * 0.28, -radius * 0.3),
      radius * 0.22,
      Paint()
        ..color = highlightColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final base = Paint();

    // Arco grande izquierda (solo contorno)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(-w * 0.05, h * 0.55), radius: w * 0.65),
      -1.1,
      1.5,
      false,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Arco mediano
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.15, h * 0.45), radius: w * 0.42),
      -0.8,
      1.8,
      false,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Esfera grande (parte inferior derecha)
    _drawSphere(canvas, Offset(w * 0.72, h * 0.72), w * 0.38, base);
    // Esfera mediana (parte superior derecha)
    _drawSphere(canvas, Offset(w * 0.82, h * 0.22), w * 0.20, base);
    // Esfera pequeña (izquierda centro)
    _drawSphere(canvas, Offset(w * 0.08, h * 0.38), w * 0.11, base);
    // Esfera tiny (superior izquierda)
    _drawSphere(canvas, Offset(w * 0.25, h * 0.08), w * 0.06, base);
  }

  @override
  bool shouldRepaint(BubblesPainter old) => old.primaryColor != primaryColor;
}

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.55),
            blurRadius: 40,
            spreadRadius: 4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
      ),
    );
  }
}
