import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sigetu/core/auth/auth_http.dart';
import 'package:sigetu/core/constants/appointment_statuses.dart';
import 'package:sigetu/core/constants/api_constants.dart';
import 'package:sigetu/core/utils/appointment_sorting.dart';
import 'package:sigetu/features/secretary/domain/secretary_appointment.dart';
import 'package:sigetu/features/secretary/domain/secretary_appointment_detail.dart';

class SecretaryAppointmentsApi {
  SecretaryAppointmentsApi({String? baseUrl, this.sede})
    : baseUrl = baseUrl ?? ApiConstants.baseUrl;

  final String baseUrl;
  final String? sede;

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

  Future<List<SecretaryAppointment>> fetchQueueAppointments() async {
    final baseUri = Uri.parse('$baseUrl/appointments/queue');
    final trimmedSede = sede?.trim();
    final queryParameters = {
      ...baseUri.queryParameters,
      if (trimmedSede != null && trimmedSede.isNotEmpty) 'sede': trimmedSede,
    };
    final url = baseUri.replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final response = await AuthHttp.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return sortByScheduledAt(
          decoded
            .whereType<Map<String, dynamic>>()
            .map(SecretaryAppointment.fromJson),
          (appointment) => appointment.scheduledAt,
        );
      }

      if (decoded is Map<String, dynamic> && decoded['items'] is List) {
        return sortByScheduledAt(
          (decoded['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(SecretaryAppointment.fromJson),
          (appointment) => appointment.scheduledAt,
        );
      }

      return [];
    }

    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 404 ||
        response.statusCode == 422) {
      throw Exception(_extractErrorMessage(response));
    }

    throw Exception('Error del servidor: ${response.statusCode}');
  }

  Future<String?> callTurn({required int appointmentId}) async {
    await updateAppointmentStatus(
      appointmentId: appointmentId,
      status: AppointmentStatuses.calling,
    );
    return null;
  }

  Future<SecretaryAppointmentDetail> fetchAppointmentDetail({
    required int appointmentId,
  }) async {
    final url = Uri.parse('$baseUrl/appointments/$appointmentId/detail');

    final response = await AuthHttp.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return SecretaryAppointmentDetail.fromJson(decoded);
      }

      throw Exception('Respuesta inválida del servidor');
    }

    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 404 ||
        response.statusCode == 422) {
      throw Exception(_extractErrorMessage(response));
    }

    throw Exception('Error del servidor: ${response.statusCode}');
  }

  Future<String?> updateAppointmentStatus({
    required int appointmentId,
    required String status,
    bool isGuest = false,
  }) async {
    final url = isGuest
        ? Uri.parse('$baseUrl/appointments/guest/$appointmentId/status')
        : Uri.parse('$baseUrl/appointments/$appointmentId/status');

    final response = await AuthHttp.patch(
      url,
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
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

  Future<DateTime> startAttention({
    required int appointmentId,
    bool isGuest = false,
  }) async {
    final url = isGuest
        ? Uri.parse(
            '$baseUrl/appointments/guest/$appointmentId/start-attention',
          )
        : Uri.parse('$baseUrl/appointments/$appointmentId/start-attention');
    final response = await AuthHttp.post(url, body: '{}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final decoded = jsonDecode(response.body);
        final raw = decoded['attention_started_at']?.toString();
        if (raw != null) {
          final str = raw.replaceFirst(RegExp(r'(Z|[+-]\d{2}:?\d{2})$'), '');
          final dt = DateTime.tryParse(str);
          if (dt != null) return dt;
        }
      } catch (_) {}
      return DateTime.now();
    }

    throw Exception(_extractErrorMessage(response));
  }

  Future<void> extendTime({
    required int appointmentId,
    bool isGuest = false,
  }) async {
    final url = isGuest
        ? Uri.parse('$baseUrl/appointments/guest/$appointmentId/extend-time')
        : Uri.parse('$baseUrl/appointments/$appointmentId/extend-time');
    final response = await AuthHttp.post(url, body: '{}');

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      return;
    }

    throw Exception(_extractErrorMessage(response));
  }

  /// Obtiene el historial de citas de invitados por device_id.
  /// Requiere JWT de invitado (role=guest) en AuthSession.
  Future<List<SecretaryAppointment>> fetchGuestHistory({
    required String deviceId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/appointments/guest/history',
    ).replace(queryParameters: {'device_id': deviceId});

    final response = await AuthHttp.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return sortByScheduledAt(
          decoded
            .whereType<Map<String, dynamic>>()
            .map(SecretaryAppointment.fromJson),
          (appointment) => appointment.scheduledAt,
        );
      }

      if (decoded is Map<String, dynamic> && decoded['items'] is List) {
        return sortByScheduledAt(
          (decoded['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(SecretaryAppointment.fromJson),
          (appointment) => appointment.scheduledAt,
        );
      }

      return [];
    }

    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 404 ||
        response.statusCode == 422) {
      throw Exception(_extractErrorMessage(response));
    }

    throw Exception('Error del servidor: ${response.statusCode}');
  }

  /// Obtiene el historial de citas de secretaría (solo las atendidas por esta secretaría).
  /// Endpoint: GET /appointments/my-history
  Future<List<SecretaryAppointment>> fetchHistory() async {
    final url = Uri.parse('$baseUrl/appointments/my-history');

    final response = await AuthHttp.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return sortByScheduledAt(
          decoded
            .whereType<Map<String, dynamic>>()
            .map(SecretaryAppointment.fromJson),
          (appointment) => appointment.scheduledAt,
        );
      }

      if (decoded is Map<String, dynamic> && decoded['items'] is List) {
        return sortByScheduledAt(
          (decoded['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(SecretaryAppointment.fromJson),
          (appointment) => appointment.scheduledAt,
        );
      }

      return [];
    }

    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 404 ||
        response.statusCode == 422) {
      throw Exception(_extractErrorMessage(response));
    }

    throw Exception('Error del servidor: ${response.statusCode}');
  }
}
