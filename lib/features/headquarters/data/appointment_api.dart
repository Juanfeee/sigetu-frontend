import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sigetu/core/auth/auth_http.dart';
import 'package:sigetu/core/constants/api_constants.dart';
import 'package:sigetu/features/headquarters/domain/appointment_request.dart';

class AppointmentApi {
  AppointmentApi({String? baseUrl, this.endpointPath = '/appointments'})
    : baseUrl = baseUrl ?? ApiConstants.baseUrl;

  final String baseUrl;
  final String endpointPath;

  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      if (body is Map<String, dynamic>) {
        if (body['detail'] is List) {
          return (body['detail'] as List).map((e) => e['msg']).join('\n');
        }
        if (body['detail'] != null) return body['detail'].toString();
        if (body['message'] != null) return body['message'].toString();
      }
    } catch (_) {}

    return 'Error desconocido';
  }

  String? _extractSuccessMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      if (body is Map<String, dynamic>) {
        final message = body['message'] ?? body['detail'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {}

    return null;
  }

  Future<String?> createAppointment(
    AppointmentRequest request, {
    String? sede,
  }) async {
    final baseUri = Uri.parse('$baseUrl$endpointPath');
    final trimmedSede = sede?.trim();
    final queryParameters = {
      ...baseUri.queryParameters,
      if (trimmedSede != null && trimmedSede.isNotEmpty) 'sede': trimmedSede,
    };
    final url = baseUri.replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final response = await AuthHttp.post(
      url,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _extractSuccessMessage(response);
    }

    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 404 ||
        response.statusCode == 409 ||
        response.statusCode == 422) {
      throw Exception(_extractErrorMessage(response));
    }

    throw Exception('Error del servidor: ${response.statusCode}');
  }

  Future<List<TimeOfDay>> fetchOccupiedSlots(
    DateTime date, {
    String? sede,
  }) async {
    final baseUri = Uri.parse('$baseUrl$endpointPath/horarios-ocupados');
    final trimmedSede = sede?.trim();
    final queryParameters = {
      ...baseUri.queryParameters,
      if (trimmedSede != null && trimmedSede.isNotEmpty) 'sede': trimmedSede,
    };
    final url = baseUri.replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final response = await AuthHttp.get(url);

    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body);
    final rawList = (body['horarios'] as List?)?.cast<dynamic>() ?? [];

    // Parse into (DateTime, status, endsAt?) triples filtrando por el día
    final entries = <({DateTime dt, String status, DateTime? endsAt})>[];
    for (final item in rawList) {
      final raw = (item is Map) ? item['scheduled_at'] : item;
      final status = (item is Map) ? (item['status'] ?? '').toString() : '';
      if (raw == null) continue;
      final str = raw.toString().replaceFirst(
        RegExp(r'(Z|[+-]\d{2}:?\d{2})$'),
        '',
      );
      // Tratar como hora Colombia (UTC-5) explícitamente
      final dtLocal = DateTime.tryParse(str);
      if (dtLocal == null) continue;
      // Adjuntar offset Colombia para tener un datetime con zona horaria correcta
      final dt = DateTime(
        dtLocal.year,
        dtLocal.month,
        dtLocal.day,
        dtLocal.hour,
        dtLocal.minute,
        dtLocal.second,
      );
      if (dt.year != date.year || dt.month != date.month || dt.day != date.day) {
        continue;
      }

      // attention_ends_at: enviado por el backend cuando el slot está en_atencion
      DateTime? endsAt;
      if (item is Map && item['attention_ends_at'] != null) {
        final endsStr = item['attention_ends_at'].toString().replaceFirst(
          RegExp(r'(Z|[+-]\d{2}:?\d{2})$'),
          '',
        );
        final endsLocal = DateTime.tryParse(endsStr);
        if (endsLocal != null) {
          endsAt = DateTime(
            endsLocal.year,
            endsLocal.month,
            endsLocal.day,
            endsLocal.hour,
            endsLocal.minute,
            endsLocal.second,
          );
        }
      }

      entries.add((dt: dt, status: status, endsAt: endsAt));
    }

    entries.sort((a, b) => a.dt.compareTo(b.dt));

    final occupied = <TimeOfDay>{};

    for (int i = 0; i < entries.length; i++) {
      final dt = entries[i].dt;
      final status = entries[i].status;

      occupied.add(TimeOfDay(hour: dt.hour, minute: dt.minute));

      if (status == 'en_atencion') {
        // Prioridad 1: attention_ends_at del backend (cubre extensiones sin pendientes)
        // Prioridad 2: siguiente pendiente en la cola
        // Prioridad 3: al menos el slot base de 15 min
        final nextDt = i + 1 < entries.length ? entries[i + 1].dt : null;
        final boundary =
            entries[i].endsAt ?? nextDt ?? dt.add(const Duration(minutes: 15));

        var cursor = dt.add(const Duration(minutes: 15));
        while (cursor.isBefore(boundary)) {
          occupied.add(TimeOfDay(hour: cursor.hour, minute: cursor.minute));
          cursor = cursor.add(const Duration(minutes: 15));
        }
      }
    }

    return occupied.toList();
  }
}
