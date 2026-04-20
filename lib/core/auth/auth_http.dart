import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sigetu/core/auth/auth_session.dart';
import 'package:sigetu/core/auth/http_client_stub.dart'
    if (dart.library.html) 'package:sigetu/core/auth/http_client_web.dart';
import 'package:sigetu/core/constants/api_constants.dart';
import 'package:sigetu/features/auth/data/auth_api.dart';

typedef _AuthorizedRequest = Future<http.Response> Function(String accessToken);

class AuthHttp {
  static Future<bool>? _refreshInFlight;

  // Cliente para Web (envía cookies automáticamente)
  static final http.Client _webClient = buildWebClient();

  static Map<String, String> authorizedJsonHeaders({String? accessToken}) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${accessToken ?? AuthSession.accessToken}',
    };
  }

  static Future<http.Response> get(Uri url) {
    return _sendWithAutoRefresh(
      (token) => _httpRequest(
        (client) =>
            client.get(url, headers: authorizedJsonHeaders(accessToken: token)),
      ),
    );
  }

  static Future<http.Response> post(Uri url, {Object? body}) {
    return _sendWithAutoRefresh(
      (token) => _httpRequest(
        (client) => client.post(
          url,
          headers: authorizedJsonHeaders(accessToken: token),
          body: body,
        ),
      ),
    );
  }

  static Future<http.Response> patch(Uri url, {Object? body}) {
    return _sendWithAutoRefresh(
      (token) => _httpRequest(
        (client) => client.patch(
          url,
          headers: authorizedJsonHeaders(accessToken: token),
          body: body,
        ),
      ),
    );
  }

  static Future<http.Response> delete(Uri url, {Object? body}) {
    return _sendWithAutoRefresh(
      (token) => _httpRequest(
        (client) => client.delete(
          url,
          headers: authorizedJsonHeaders(accessToken: token),
          body: body,
        ),
      ),
    );
  }

  static Future<http.Response> _httpRequest(
    Future<http.Response> Function(http.Client client) requestFn,
  ) {
    if (kIsWeb) {
      return requestFn(_webClient);
    }
    return requestFn(http.Client());
  }

  static Future<http.Response> _sendWithAutoRefresh(
    _AuthorizedRequest request,
  ) async {
    if (!AuthSession.hasToken) {
      throw Exception('No autenticado: se requiere token');
    }

    final firstToken = AuthSession.accessToken!;
    var response = await request(firstToken);

    if (response.statusCode != 401) {
      return response;
    }

    final refreshed = await _refreshAccessToken();
    if (!refreshed || !AuthSession.hasToken) {
      return response;
    }

    response = await request(AuthSession.accessToken!);
    return response;
  }

  static Future<bool> _refreshAccessToken() async {
    if (kIsWeb) {
      // Web: el refresh token está en cookie HttpOnly
      return _refreshWebToken();
    }

    // Android: necesita refresh_token en body
    if (!AuthSession.hasRefreshToken) {
      await AuthSession.expireSession();
      return false;
    }

    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final completer = Completer<bool>();
    _refreshInFlight = completer.future;

    try {
      final refreshToken = AuthSession.refreshToken!;
      final refreshResponse = await AuthApi().refresh(
        refreshToken: refreshToken,
      );

      AuthSession.setTokens(
        access: refreshResponse.accessToken,
        refresh: refreshResponse.refreshToken ?? refreshToken,
      );

      completer.complete(true);
      return true;
    } catch (_) {
      await AuthSession.expireSession();
      completer.complete(false);
      return false;
    } finally {
      _refreshInFlight = null;
    }
  }

  static Future<bool> _refreshWebToken() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final completer = Completer<bool>();
    _refreshInFlight = completer.future;

    try {
      // Web: POST sin body, la cookie HttpOnly se envía sola
      final response = await _httpRequest(
        (client) => client.post(
          Uri.parse('${ApiConstants.baseUrl}/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccessToken = body['access_token'] as String?;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          AuthSession.setTokens(access: newAccessToken);
          completer.complete(true);
          return true;
        }
      }

      completer.complete(false);
      return false;
    } catch (_) {
      await AuthSession.expireSession();
      completer.complete(false);
      return false;
    } finally {
      _refreshInFlight = null;
    }
  }
}
