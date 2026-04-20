import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sigetu/core/auth/auth_http.dart';
import 'package:sigetu/core/constants/api_constants.dart';
import 'package:sigetu/features/headquarters/domain/categoria_contexto.dart';

class CategoriaContextosApi {
  CategoriaContextosApi({String? baseUrl})
    : baseUrl = baseUrl ?? ApiConstants.baseUrl;

  final String baseUrl;

  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['detail'] is List) {
          return (body['detail'] as List).map((item) => item['msg']).join('\n');
        }
        if (body['detail'] != null) return body['detail'].toString();
        if (body['message'] != null) return body['message'].toString();
      }
    } catch (_) {}
    return 'Error desconocido';
  }

  Future<List<CategoriaContexto>> fetchContextosActivosPorCategoria(
    int categoriaId,
  ) async {
    final url = Uri.parse('$baseUrl/contextos').replace(
      queryParameters: {'categoria_id': '$categoriaId', 'activos': 'true'},
    );

    final response = await AuthHttp.get(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(CategoriaContexto.fromJson)
            .where((contexto) => contexto.activo)
            .toList();
      }
      throw Exception('Formato inválido al cargar contextos');
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