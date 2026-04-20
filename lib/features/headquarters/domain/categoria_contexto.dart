class CategoriaContexto {
  const CategoriaContexto({
    required this.id,
    required this.categoriaId,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.activo,
  });

  final int id;
  final int categoriaId;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final bool activo;

  factory CategoriaContexto.fromJson(Map<String, dynamic> json) {
    return CategoriaContexto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      categoriaId: (json['categoria_id'] as num?)?.toInt() ?? 0,
      codigo: (json['codigo'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: json['descripcion']?.toString(),
      activo: json['activo'] == true || json['activo'] == 1,
    );
  }
}