import 'package:flutter/foundation.dart';

class ApiConstants {

  // URL FIJA DEL BACKEND
  static const String baseUrl = 'https://sigetu-bk.onrender.com';

  // WebSocket opcional
  static const String appointmentsWsUrlOverride = '';

  static const int backendTimezoneOffsetMinutes = -300;

  static String get appointmentsWsUrl {

    if (appointmentsWsUrlOverride.isNotEmpty) {
      return appointmentsWsUrlOverride;
    }

    final uri = Uri.parse(baseUrl);

    final scheme = uri.scheme == 'https'
        ? 'wss'
        : 'ws';

    return uri
        .replace(
          scheme: scheme,
          path: '/appointments/ws',
        )
        .toString();
  }
}