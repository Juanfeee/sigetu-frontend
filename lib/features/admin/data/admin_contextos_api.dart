import 'dart:convert';

import 'package:sigetu/core/auth/auth_http.dart';
import 'package:sigetu/core/constants/api_constants.dart';
import 'package:sigetu/features/headquarters/domain/categoria_contexto.dart';

class AdminContextosApi {
  AdminContextosApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConstants.baseUrl;

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

  Future<List<CategoriaContexto>> fetchContextosPorCategoria(int categoriaId) async {
    final url = Uri.parse('$baseUrl/contextos').replace(
      queryParameters: {'categoria_id': '$categoriaId'},
    );

    final response = await AuthHttp.get(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(CategoriaContexto.fromJson)
            .toList();
      }
      throw Exception('Formato inválido al cargar contextos');
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

  Future<String?> createContexto({
    required int categoriaId,
    required String codigo,
    required String nombre,
    String? descripcion,
    required bool activo,
  }) async {
    final url = Uri.parse('$baseUrl/contextos');

    final payload = <String, dynamic>{
      'categoria_id': categoriaId,
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

  Future<String?> updateContexto(
    int contextoId, {
    required String codigo,
    required String nombre,
    String? descripcion,
    required bool activo,
  }) async {
    final url = Uri.parse('$baseUrl/contextos/$contextoId');

    final payload = <String, dynamic>{
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'descripcion': descripcion?.trim(),
      'activo': activo,
    };

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

  Future<String?> deleteContexto(int contextoId) async {
    final url = Uri.parse('$baseUrl/contextos/$contextoId');
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
