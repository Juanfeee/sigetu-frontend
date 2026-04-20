import 'package:sigetu/core/utils/backend_datetime.dart';

class AcademicProgram {
  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final bool activo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AcademicProgram({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.activo,
    this.createdAt,
    this.updatedAt,
  });

  factory AcademicProgram.fromJson(Map<String, dynamic> json) => AcademicProgram(
      id: (json['id'] as num).toInt(),
        codigo: (json['codigo'] ?? '').toString(),
        nombre: (json['nombre'] ?? '').toString(),
        descripcion: json['descripcion']?.toString(),
      activo: json['activo'] == true || json['activo'] == 1,
        createdAt: json['created_at'] == null
            ? null
            : BackendDateTime.parse(json['created_at']),
        updatedAt: json['updated_at'] == null
            ? null
            : BackendDateTime.parse(json['updated_at']),
      );
}