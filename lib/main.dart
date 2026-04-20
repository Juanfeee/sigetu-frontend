import 'package:flutter/material.dart';
import 'package:sigetu/features/admin/presentation/admin_routes.dart';
import 'package:sigetu/core/auth/auth_session.dart';
import 'package:sigetu/features/secretary/presentation/secretary_routes.dart';
import 'package:sigetu/features/student_dashboard/presentation/student_dashboard_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/notifications/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await AuthSession.restore();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  int _lastHandledInvalidation = 0;
  bool _isRedirectingToLogin = false;

  @override
  void initState() {
    super.initState();
    AuthSession.sessionInvalidation.addListener(_handleSessionInvalidation);
    NotificationService.initialize(_navigatorKey);
  }

  @override
  void dispose() {
    AuthSession.sessionInvalidation.removeListener(_handleSessionInvalidation);
    super.dispose();
  }

  void _handleSessionInvalidation() {
    final currentEvent = AuthSession.sessionInvalidation.value;
    if (_isRedirectingToLogin || currentEvent == _lastHandledInvalidation) {
      return;
    }

    _lastHandledInvalidation = currentEvent;
    _isRedirectingToLogin = true;
    _redirectToLoginWithRetry();
  }

  void _redirectToLoginWithRetry({int attempt = 0}) {
    if (!mounted) {
      _isRedirectingToLogin = false;
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      if (attempt >= 12) {
        _isRedirectingToLogin = false;
        return;
      }

      Future<void>.delayed(const Duration(milliseconds: 120), () {
        _redirectToLoginWithRetry(attempt: attempt + 1);
      });
      return;
    }

    navigator.pushNamedAndRemoveUntil(AuthRoutes.login, (route) => false);

    _scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Tu sesión expiró. Inicia sesión nuevamente.'),
      ),
    );

    _isRedirectingToLogin = false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'SIGETU - UNIAUTÓNOMA',

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      initialRoute: AuthRoutes.login,

      routes: {
        ...AuthRoutes.routes,
        ...AdminRoutes.routes,
        ...SecretaryRoutes.routes,
        ...StudentDashboardRoutes.routes,
      },
    );
  }
}
