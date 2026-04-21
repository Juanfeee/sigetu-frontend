import 'dart:convert';

import 'package:sigetu/core/auth/auth_http.dart';
import 'package:sigetu/core/constants/api_constants.dart';
import 'package:sigetu/features/headquarters/domain/sede.dart';

class CreateSedeResult {
  const CreateSedeResult({this.message, this.sedeId});

  final String? message;
  final int? sedeId;
}

class AdminSedesApi {
  AdminSedesApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConstants.baseUrl;

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

  int? _extractSedeId(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;

      final candidates = [
        decoded['id'],
        decoded['sede_id'],
        (decoded['data'] is Map<String, dynamic>)
            ? (decoded['data'] as Map<String, dynamic>)['id']
            : null,
        (decoded['item'] is Map<String, dynamic>)
            ? (decoded['item'] as Map<String, dynamic>)['id']
            : null,
      ];

      for (final raw in candidates) {
        if (raw is int) return raw;
        final parsed = int.tryParse(raw?.toString() ?? '');
        if (parsed != null && parsed > 0) return parsed;
      }
    } catch (_) {}

    return null;
  }

  Future<List<Sede>> fetchSedes() async {
    final url = Uri.parse('$baseUrl/sedes');
    final response = await AuthHttp.get(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().map(Sede.fromJson).toList();
      }
      throw Exception('Formato inválido al cargar sedes');
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

  Future<CreateSedeResult> createSede({
    required String codigo,
    required String nombre,
    required String ubicacion,
    String? descripcion,
    required bool esPublica,
    required bool filtrarCitasPorPrograma,
    required bool activo,
  }) async {
    final url = Uri.parse('$baseUrl/sedes');

    final payload = <String, dynamic>{
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'ubicacion': ubicacion.trim(),
      'es_publica': esPublica,
      'filtrar_citas_por_programa': filtrarCitasPorPrograma,
      'activo': activo,
    };

    final normalizedDescription = descripcion?.trim();
    if (normalizedDescription != null && normalizedDescription.isNotEmpty) {
      payload['descripcion'] = normalizedDescription;
    }

    final response = await AuthHttp.post(url, body: jsonEncode(payload));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return CreateSedeResult(
        message: _extractSuccessMessage(response.body),
        sedeId: _extractSedeId(response.body),
      );
    }

    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 422) {
      throw Exception(_extractErrorMessage(response.body));
    }

    throw Exception('Error del servidor: ${response.statusCode}');
  }

  Future<String?> updateSede(
    int sedeId, {
    required String codigo,
    required String nombre,
    required String ubicacion,
    String? descripcion,
    required bool esPublica,
    required bool filtrarCitasPorPrograma,
    required bool activo,
  }) async {
    final url = Uri.parse('$baseUrl/sedes/$sedeId');
    final payload = <String, dynamic>{
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'ubicacion': ubicacion.trim(),
      'es_publica': esPublica,
      'filtrar_citas_por_programa': filtrarCitasPorPrograma,
      'activo': activo,
    };

    final normalizedDescription = descripcion?.trim();
    if (normalizedDescription != null && normalizedDescription.isNotEmpty) {
      payload['descripcion'] = normalizedDescription;
    }

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

  Future<String?> deleteSede(int sedeId) async {
    final url = Uri.parse('$baseUrl/sedes/$sedeId');
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

  Future<String?> createHorarioSede(
    int sedeId, {
    required int diaSemana,
    required String horaInicio,
    required String horaFin,
    bool activo = true,
  }) async {
    final url = Uri.parse('$baseUrl/sedes/$sedeId/horarios');
    final payload = <String, dynamic>{
      'dia_semana': diaSemana,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'activo': activo,
    };

    final response = await AuthHttp.post(url, body: jsonEncode(payload));

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

  Future<String?> createHorariosSedeLote(
    int sedeId, {
    required List<Map<String, dynamic>> bloques,
  }) async {
    final url = Uri.parse('$baseUrl/sedes/$sedeId/horarios/lote');
    final payload = <String, dynamic>{
      'bloques': bloques,
    };

    final response = await AuthHttp.post(url, body: jsonEncode(payload));

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

  Future<List<Map<String, dynamic>>> fetchHorariosSede(int sedeId) async {
    final url = Uri.parse('$baseUrl/sedes/$sedeId/horarios');
    final response = await AuthHttp.get(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
      if (decoded is Map<String, dynamic>) {
        for (final key in const ['items', 'results', 'data', 'horarios']) {
          final raw = decoded[key];
          if (raw is List) {
            return raw.whereType<Map<String, dynamic>>().toList();
          }
        }
      }
      throw Exception('Formato inválido al cargar horarios');
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

  Future<String?> updateHorarioSede(
    int sedeId,
    int horarioId, {
    int? diaSemana,
    String? horaInicio,
    String? horaFin,
    bool? activo,
  }) async {
    final payload = <String, dynamic>{};
    if (diaSemana != null) payload['dia_semana'] = diaSemana;
    if (horaInicio != null) payload['hora_inicio'] = horaInicio;
    if (horaFin != null) payload['hora_fin'] = horaFin;
    if (activo != null) payload['activo'] = activo;

    if (payload.isEmpty) {
      throw Exception('No hay cambios para actualizar');
    }

    final url = Uri.parse('$baseUrl/sedes/$sedeId/horarios/$horarioId');
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

  Future<String?> deleteHorarioSede(int sedeId, int horarioId) async {
    final url = Uri.parse('$baseUrl/sedes/$sedeId/horarios/$horarioId');
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
