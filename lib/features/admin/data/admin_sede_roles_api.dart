import 'dart:convert';

import 'package:sigetu/core/auth/auth_http.dart';
import 'package:sigetu/core/constants/api_constants.dart';



class AdminStaffUser {
  const AdminStaffUser({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final int id;
  final String fullName;
  final String email;

  String get displayLabel {
    if (email.isEmpty) return fullName;
    return '$fullName ($email)';
  }

  factory AdminStaffUser.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'] ?? json['user_id'];
    final fullNameRaw =
        json['full_name'] ?? json['nombre_completo'] ?? json['name'];
    final emailRaw = json['email'] ?? json['correo'];

    return AdminStaffUser(
      id: _toInt(idRaw),
      fullName: (fullNameRaw ?? '').toString().trim(),
      email: (emailRaw ?? '').toString().trim(),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}


class AdminSedeRolesApi {
  AdminSedeRolesApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConstants.baseUrl;

  final String baseUrl;

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        if (decoded['detail'] is List) {
          return (decoded['detail'] as List).map((item) => item['msg']).join('\n');
        }

        if (decoded['detail'] != null) {
          return decoded['detail'].toString();
        }

        if (decoded['message'] != null) {
          return decoded['message'].toString();
        }
      }
    } catch (_) {}

    return 'Error desconocido';
  }


  List<Map<String, dynamic>> _extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }

    if (decoded is Map<String, dynamic>) {
      final keys = ['items', 'results', 'data', 'roles', 'users', 'staff'];
      for (final key in keys) {
        final raw = decoded[key];
        if (raw is List) {
          return raw.whereType<Map<String, dynamic>>().toList();
        }
      }
    }

    return const [];
  }

  Future<List<AdminStaffUser>> fetchStaffUsers({
    bool? sinSede,
    int? sedeId,
    bool? activo,
  }) async {
    final queryParameters = <String, String>{};
    if (sinSede != null) {
      queryParameters['sin_sede'] = sinSede.toString();
    }
    if (sedeId != null && sedeId > 0) {
      queryParameters['sede_id'] = '$sedeId';
    }
    if (activo != null) {
      queryParameters['activo'] = activo.toString();
    }

    final url = Uri.parse('$baseUrl/staff').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    final response = await AuthHttp.get(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      final list = _extractList(decoded);
      return list
          .map(AdminStaffUser.fromJson)
          .where((user) => user.id > 0)
          .toList();
    }

    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 404 ||
        response.statusCode == 422) {
      throw Exception(_extractErrorMessage(response.body));
    }

    throw Exception('Error del servidor: ${response.statusCode}');
  }

  Future<List<AdminStaffUser>> fetchStaffBySede({
    required int sedeId,
    bool activo = true,
  }) {
    return fetchStaffUsers(sedeId: sedeId, activo: activo);
  }

  Future<String?> assignStaffToSede({
    required int userId,
    required int sedeId,
    bool activo = true,
  }) async {
    final url = Uri.parse('$baseUrl/staff');
    final payload = <String, dynamic>{
      'user_id': userId,
      'sede_id': sedeId,
      'activo': activo,
    };

    final response = await AuthHttp.post(url, body: jsonEncode(payload));

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final message = decoded['message'] ?? decoded['detail'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
      } catch (_) {}

      return null;
    }

    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 404 ||
        response.statusCode == 409 ||
        response.statusCode == 422) {
      throw Exception(_extractErrorMessage(response.body));
    }

    throw Exception('Error del servidor: ${response.statusCode}');
  }

}
