class SedeCategoria {
  const SedeCategoria({
    required this.id,
    required this.sedeId,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.activo,
  });

  final int id;
  final int sedeId;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final bool activo;

  factory SedeCategoria.fromJson(Map<String, dynamic> json) {
    return SedeCategoria(
      id: (json['id'] as num?)?.toInt() ?? 0,
      sedeId: (json['sede_id'] as num?)?.toInt() ?? 0,
      codigo: (json['codigo'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: json['descripcion']?.toString(),
      activo: json['activo'] == true || json['activo'] == 1,
    );
  }
}