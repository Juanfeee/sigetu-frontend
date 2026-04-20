import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sigetu/core/auth/auth_http.dart';
import 'package:sigetu/core/constants/api_constants.dart';
import 'package:sigetu/features/headquarters/domain/sede_categoria.dart';

class SedeCategoriasApi {
  SedeCategoriasApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConstants.baseUrl;

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

  Future<List<SedeCategoria>> fetchCategoriasActivasPorSede(int sedeId) async {
    final url = Uri.parse('$baseUrl/categorias').replace(
      queryParameters: {'sede_id': '$sedeId', 'activos': 'true'},
    );

    final response = await AuthHttp.get(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(SedeCategoria.fromJson)
            .where((categoria) => categoria.activo)
            .toList();
      }
      throw Exception('Formato inválido al cargar categorías');
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