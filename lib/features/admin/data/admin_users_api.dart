import 'dart:convert';

import 'package:sigetu/core/auth/auth_http.dart';
import 'package:sigetu/core/constants/api_constants.dart';
import 'package:sigetu/core/utils/backend_datetime.dart';
import 'package:sigetu/features/shared/data/academic_programs_api.dart';
import 'package:sigetu/features/shared/domain/academic_program.dart';

class AdminRoleOption {
  const AdminRoleOption({required this.id, required this.name});

  final int id;
  final String name;

  factory AdminRoleOption.fromJson(Map<String, dynamic> json) {
    return AdminRoleOption(
      id: _toInt(json['id']),
      name: (json['name'] ?? json['nombre'] ?? '').toString().trim(),
    );
  }
}

class AdminUserItem {
  const AdminUserItem({
    required this.id,
    required this.email,
    required this.fullName,
    this.programaAcademicoId,
    this.programaAcademicoNombre,
    this.roleId,
    this.roleName,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String email;
  final String fullName;
  final int? programaAcademicoId;
  final String? programaAcademicoNombre;
  final int? roleId;
  final String? roleName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminUserItem.fromJson(Map<String, dynamic> json) {
    final programaRaw = json['programa_academico'];
    final roleRaw = json['role'];

    return AdminUserItem(
      id: _toInt(json['id']),
      email: (json['email'] ?? '').toString().trim(),
      fullName: (json['full_name'] ?? json['nombre_completo'] ?? '').toString().trim(),
      programaAcademicoId: _nullableInt(
        json['programa_academico_id'] ??
            (programaRaw is Map<String, dynamic> ? programaRaw['id'] : null),
      ),
      programaAcademicoNombre: (json['programa_academico_nombre'] ??
              json['programa_academico_name'] ??
              json['programa_academico'] ??
              json['academic_program'] ??
              (programaRaw is Map<String, dynamic> ? programaRaw['nombre'] : null) ??
              (programaRaw is Map<String, dynamic> ? programaRaw['name'] : null))
          ?.toString(),
      roleId: _nullableInt(
        json['role_id'] ??
            json['rol_id'] ??
            (roleRaw is Map<String, dynamic> ? roleRaw['id'] : null),
      ),
      roleName: (json['role_name'] ??
              json['rol_nombre'] ??
              json['rol'] ??
              (roleRaw is Map<String, dynamic> ? roleRaw['name'] : null) ??
              (roleRaw is Map<String, dynamic> ? roleRaw['nombre'] : null))
          ?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: json['created_at'] == null
          ? null
          : BackendDateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] == null
          ? null
          : BackendDateTime.parse(json['updated_at']),
    );
  }
}

class AdminUsersApi {
  AdminUsersApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConstants.baseUrl;

  final String baseUrl;
  late final AcademicProgramsApi _programsApi = AcademicProgramsApi(
    baseUrl: baseUrl,
  );

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

  String? _extractSuccessMessage(String body) {
    if (body.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['detail'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {}

    return null;
  }

  List<Map<String, dynamic>> _extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }

    if (decoded is Map<String, dynamic>) {
      const keys = ['items', 'results', 'data', 'users', 'roles'];
      for (final key in keys) {
        final raw = decoded[key];
        if (raw is List) {
          return raw.whereType<Map<String, dynamic>>().toList();
        }
      }
    }

    return const [];
  }

  Future<List<AdminUserItem>> fetchUsers() async {
    final url = Uri.parse('$baseUrl/users');
    final response = await AuthHttp.get(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      final list = _extractList(decoded);
      return list
          .map(AdminUserItem.fromJson)
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

  Future<AdminUserItem> fetchUserById(int userId) async {
    final url = Uri.parse('$baseUrl/users/$userId');
    final response = await AuthHttp.get(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['data'] is Map<String, dynamic>) {
          return AdminUserItem.fromJson(decoded['data'] as Map<String, dynamic>);
        }
        return AdminUserItem.fromJson(decoded);
      }
      throw Exception('Formato inválido al cargar usuario');
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

  Future<String?> createUser({
    required String email,
    required String fullName,
    required String password,
    required int programaAcademicoId,
    required int roleId,
    required bool isActive,
  }) async {
    final url = Uri.parse('$baseUrl/users');
    final payload = <String, dynamic>{
      'email': email.trim(),
      'full_name': fullName.trim(),
      'password': password,
      'programa_academico_id': programaAcademicoId,
      'role_id': roleId,
      'is_active': isActive,
    };

    final response = await AuthHttp.post(url, body: jsonEncode(payload));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _extractSuccessMessage(response.body);
    }

    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 409 ||
        response.statusCode == 422) {
      throw Exception(_extractErrorMessage(response.body));
    }

    throw Exception('Error del servidor: ${response.statusCode}');
  }

  Future<String?> updateUser(
    int userId, {
    String? fullName,
    int? programaAcademicoId,
    int? roleId,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{};

    if (fullName != null) {
      payload['full_name'] = fullName.trim();
    }
    if (programaAcademicoId != null) {
      payload['programa_academico_id'] = programaAcademicoId;
    }
    if (roleId != null) {
      payload['role_id'] = roleId;
    }
    if (isActive != null) {
      payload['is_active'] = isActive;
    }

    if (payload.isEmpty) {
      throw Exception('No hay cambios para actualizar');
    }

    final url = Uri.parse('$baseUrl/users/$userId');
    final response = await AuthHttp.patch(url, body: jsonEncode(payload));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _extractSuccessMessage(response.body);
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

  Future<String?> deleteUser(int userId) async {
    final url = Uri.parse('$baseUrl/users/$userId');
    final response = await AuthHttp.delete(url);

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      return _extractSuccessMessage(response.body);
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

  Future<List<AdminRoleOption>> fetchRoles() async {
    final url = Uri.parse('$baseUrl/roles');
    final response = await AuthHttp.get(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      final list = _extractList(decoded);
      return list
          .map(AdminRoleOption.fromJson)
          .where((role) => role.id > 0 && role.name.isNotEmpty)
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

  Future<List<AcademicProgram>> fetchPrograms() {
    return _programsApi.fetchPrograms(onlyActive: false);
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(dynamic value) {
  final parsed = _toInt(value);
  return parsed > 0 ? parsed : null;
}
