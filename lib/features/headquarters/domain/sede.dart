import 'package:sigetu/core/utils/backend_datetime.dart';

class Sede {
  const Sede({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.ubicacion,
    this.descripcion,
    required this.esPublica,
    required this.filtrarCitasPorPrograma,
    required this.activo,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String? ubicacion;
  final String? descripcion;
  final bool esPublica;
  final bool filtrarCitasPorPrograma;
  final bool activo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Sede.fromJson(Map<String, dynamic> json) {
    return Sede(
      id: (json['id'] as num).toInt(),
      codigo: (json['codigo'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      // rol eliminado
      ubicacion: json['ubicacion']?.toString(),
      descripcion: json['descripcion']?.toString(),
      esPublica: json['es_publica'] == true || json['es_publica'] == 1,
      filtrarCitasPorPrograma:
          json['filtrar_citas_por_programa'] == true ||
          json['filtrar_citas_por_programa'] == 1,
      activo: json['activo'] == true || json['activo'] == 1,
      createdAt: json['created_at'] == null
          ? null
          : BackendDateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] == null
          ? null
          : BackendDateTime.parse(json['updated_at']),
    );
  }
}