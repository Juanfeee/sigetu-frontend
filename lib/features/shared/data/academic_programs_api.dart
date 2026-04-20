import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sigetu/core/auth/http_client_stub.dart'
    if (dart.library.html) 'package:sigetu/core/auth/http_client_web.dart';
import 'package:sigetu/core/constants/api_constants.dart';
import 'package:sigetu/features/shared/domain/academic_program.dart';

class AcademicProgramsApi {
  AcademicProgramsApi({String? baseUrl})
    : baseUrl = baseUrl ?? ApiConstants.baseUrl;

  final String baseUrl;

  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      if (body is Map<String, dynamic>) {
        if (body['detail'] is List) {
          return (body['detail'] as List).map((item) => item['msg']).join('\n');
        }

        if (body['detail'] != null) {
          return body['detail'].toString();
        }

        if (body['message'] != null) {
          return body['message'].toString();
        }
      }
    } catch (_) {}

    return 'Error desconocido';
  }

  Future<List<AcademicProgram>> fetchPrograms({bool onlyActive = false}) async {
    final url = Uri.parse('$baseUrl/programas-academicos');

    final response = await _httpRequest(
      (client) => client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        final programs = decoded
            .whereType<Map<String, dynamic>>()
            .map(AcademicProgram.fromJson)
            .toList();

        if (!onlyActive) {
          return programs;
        }

        return programs.where((program) => program.activo).toList();
      }

      throw Exception('Formato inválido al cargar programas académicos');
    }

    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 422) {
      throw Exception(_extractErrorMessage(response));
    }

    throw Exception('Error del servidor: ${response.statusCode}');
  }

  Future<http.Response> _httpRequest(
    Future<http.Response> Function(http.Client client) requestFn,
  ) {
    if (kIsWeb) {
      return requestFn(buildWebClient());
    }
    return requestFn(http.Client());
  }
}