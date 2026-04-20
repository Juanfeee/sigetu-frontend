import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:sigetu/core/auth/auth_session.dart';
import 'package:sigetu/core/utils/device_id.dart';
import 'package:sigetu/core/constants/api_constants.dart';

class FcmTokenSync {
  // VAPID Key para web (debe coincidir con la del backend)
  static const String _vapidKey =
      'BI4HFOmLbcikn8KYWub-wX9DM3n_kRkpTW58ZePgp8fH-_zmGW9BnKAssJM0Ae1x0pYJzyGWRxKBzvIN6tdx-qQ';

  static Future<void> syncFcmToken() async {
    print('[FCM Token Sync] Iniciando sincronización...');

    // Obtener token FCM (usando VAPID key en web)
    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb ? _vapidKey : null,
    );

    print(
      '[FCM Token Sync] Token obtenido: ${token != null ? "${token.substring(0, 20)}..." : "null"}',
    );
    print('[FCM Token Sync] Platform: ${kIsWeb ? "web" : "mobile"}');

    if (token == null || !AuthSession.hasToken) {
      print('[FCM Token Sync] No hay token o no hay sesión activa');
      return;
    }

    final deviceId = await DeviceId.get();
    final platform = kIsWeb
        ? 'web'
        : Platform.isAndroid
        ? 'android'
        : Platform.isIOS
        ? 'ios'
        : 'unknown';

    print('[FCM Token Sync] Device ID: $deviceId');
    print('[FCM Token Sync] Platform: $platform');

    final url = Uri.parse('${ApiConstants.baseUrl}/notifications/device-token');

    print('[FCM Token Sync] Enviando a: ${url.toString()}');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${AuthSession.accessToken}',
        'Content-Type': 'application/json',
      },
      body:
          '{"device_id": "$deviceId", "fcm_token": "$token", "platform": "$platform"}',
    );

    print('[FCM Token Sync] Response status: ${response.statusCode}');
    print('[FCM Token Sync] Response body: ${response.body}');
  }

  static void listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (!AuthSession.hasToken) return;
      final deviceId = await DeviceId.get();
      final platform = kIsWeb
          ? 'web'
          : Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : 'unknown';
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/notifications/device-token',
      );
      await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${AuthSession.accessToken}',
          'Content-Type': 'application/json',
        },
        body:
            '{"device_id": "$deviceId", "fcm_token": "$newToken", "platform": "$platform"}',
      );
    });
  }
}
