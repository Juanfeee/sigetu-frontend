import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sigetu/core/auth/auth_http.dart';
import 'package:sigetu/core/auth/auth_session.dart';
import 'package:sigetu/core/constants/api_constants.dart';
import 'package:sigetu/core/utils/appointment_sorting.dart';
import 'package:sigetu/features/headquarters/domain/appointment_request.dart';
import 'package:sigetu/features/student_dashboard/domain/student_turn.dart';

class StudentTurnsApi {
  StudentTurnsApi({
    String? baseUrl,
    this.endpointPath = '/appointments/me/current',
  }) : baseUrl = baseUrl ?? ApiConstants.baseUrl;

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

  Future<List<StudentTurn>> fetchMyTurns() async {
    return _fetchTurnsByPath(endpointPath);
  }

  Future<List<StudentTurn>> fetchMyTurnsHistory() async {
    return _fetchTurnsByPath('/appointments/me/history');
  }

  /// Obtiene las citas de un invitado por device_id.
  /// Requiere JWT de invitado (role=guest) en AuthSession.
  Future<List<StudentTurn>> fetchGuestTurns(String deviceId) async {
    final url = Uri.parse(
      '$baseUrl/appointments/guest',
    ).replace(queryParameters: {'device_id': deviceId});

    final response = await AuthHttp.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return sortByScheduledAt(
          decoded
            .whereType<Map<String, dynamic>>()
            .map(StudentTurn.fromJson),
          (turn) => turn.scheduledAt,
        );
      }
      if (decoded is Map<String, dynamic> && decoded['items'] is List) {
        return sortByScheduledAt(
          (decoded['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(StudentTurn.fromJson),
          (turn) => turn.scheduledAt,
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

  /// Obtiene el historial de citas de un invitado por device_id.
  /// Requiere JWT de invitado (role=guest) en AuthSession.
  Future<List<StudentTurn>> fetchGuestHistory(String deviceId) async {
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
            .map(StudentTurn.fromJson),
          (turn) => turn.scheduledAt,
        );
      }
      if (decoded is Map<String, dynamic> && decoded['items'] is List) {
        return sortByScheduledAt(
          (decoded['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(StudentTurn.fromJson),
          (turn) => turn.scheduledAt,
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

  Future<List<StudentTurn>> _fetchTurnsByPath(String path) async {
    final url = Uri.parse('$baseUrl$path');

    final response = await AuthHttp.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return sortByScheduledAt(
          decoded
            .whereType<Map<String, dynamic>>()
            .map(StudentTurn.fromJson),
          (turn) => turn.scheduledAt,
        );
      }

      if (decoded is Map<String, dynamic> && decoded['items'] is List) {
        return sortByScheduledAt(
          (decoded['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(StudentTurn.fromJson),
          (turn) => turn.scheduledAt,
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

  Future<String?> updateAppointment({
    required int appointmentId,
    required AppointmentRequest request,
  }) async {
    // Si es invitado, usar endpoint de invitado
    Uri url;
    if (AuthSession.isGuest) {
      url = Uri.parse('$baseUrl/appointments/guest/$appointmentId');
    } else {
      url = Uri.parse('$baseUrl/appointments/$appointmentId');
    }

    final response = await AuthHttp.patch(
      url,
      body: jsonEncode(request.toJson()),
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

  Future<String?> cancelAppointment({required int appointmentId}) async {
    // Si es invitado, usar endpoint de invitado
    Uri url;
    if (AuthSession.isGuest) {
      url = Uri.parse('$baseUrl/appointments/guest/$appointmentId/cancel');
      print('[Cancel Appointment] Invitado: ${url.toString()}');
    } else {
      url = Uri.parse('$baseUrl/appointments/$appointmentId/cancel');
      print('[Cancel Appointment] Estudiante: ${url.toString()}');
    }

    print('[Cancel Appointment] Is Guest: ${AuthSession.isGuest}');
    print('[Cancel Appointment] Appointment ID: $appointmentId');

    final response = await AuthHttp.patch(url);

    print('[Cancel Appointment] Response status: ${response.statusCode}');
    print('[Cancel Appointment] Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      return _extractSuccessMessage(response);
    }

    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 404 ||
        response.statusCode == 409 ||
        response.statusCode == 422) {
      final errorMessage = _extractErrorMessage(response);
      print('[Cancel Appointment] Error: $errorMessage');
      throw Exception(errorMessage);
    }

    throw Exception('Error del servidor: ${response.statusCode}');
  }
}
