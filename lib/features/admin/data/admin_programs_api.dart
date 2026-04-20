import 'dart:convert';

import 'package:sigetu/core/auth/auth_http.dart';
import 'package:sigetu/core/constants/api_constants.dart';
import 'package:sigetu/features/shared/data/academic_programs_api.dart';
import 'package:sigetu/features/shared/domain/academic_program.dart';

class AdminProgramsApi {
  AdminProgramsApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConstants.baseUrl;

  final String baseUrl;
  late final AcademicProgramsApi _programsApi = AcademicProgramsApi(
    baseUrl: baseUrl,
  );

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        if (decoded['detail'] is List) {
          return (decoded['detail'] as List)
              .map((item) => item['msg'])
              .join('\n');
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

  Future<List<AcademicProgram>> fetchPrograms() async {
    return _programsApi.fetchPrograms();
  }
 // Crea un nuevo programa académico.
  Future<String?> createProgram({
    required String codigo,
    required String nombre,
    String? descripcion,
    bool activo = true,
  }) async {
    final url = Uri.parse('$baseUrl/programas-academicos');

    final payload = <String, dynamic>{
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'activo': activo,
    };

    final normalizedDescription = descripcion?.trim();
    if (normalizedDescription != null && normalizedDescription.isNotEmpty) {
      payload['descripcion'] = normalizedDescription;
    }

    final response = await AuthHttp.post(url, body: jsonEncode(payload));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _extractSuccessMessage(response.body);
    }

    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 422) {
      throw Exception(_extractErrorMessage(response.body));
    }

    throw Exception('Error del servidor: ${response.statusCode}');
  }
 // Actualiza un programa académico existente. Solo se envían los campos que realmente cambiaron.
  Future<String?> updateProgram(
    int programId, {
    String? codigo,
    String? nombre,
    String? descripcion,
    bool? activo,
  }) async {
    // PATCH parcial: solo enviamos los campos que realmente vienen definidos.
    final payload = <String, dynamic>{};

    if (codigo != null) {
      payload['codigo'] = codigo.trim();
    }
    if (nombre != null) {
      payload['nombre'] = nombre.trim();
    }
    if (descripcion != null) {
      payload['descripcion'] = descripcion.trim();
    }
    if (activo != null) {
      payload['activo'] = activo;
    }

    if (payload.isEmpty) {
      throw Exception('No hay cambios para actualizar');
    }

    final url = Uri.parse('$baseUrl/programas-academicos/$programId');
    final response = await AuthHttp.patch(url, body: jsonEncode(payload));

    if (response.statusCode == 200 || response.statusCode == 201) {
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

  Future<String?> deleteProgram(int programId) async {
    final url = Uri.parse('$baseUrl/programas-academicos/$programId');
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
}