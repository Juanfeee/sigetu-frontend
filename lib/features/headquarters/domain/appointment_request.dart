class AppointmentRequest {
  AppointmentRequest({
    this.contextoId,
    this.category,
    this.context,
    required this.scheduledAt,
  });

  final int? contextoId;
  final String? category;
  final String? context;
  final DateTime scheduledAt;

  String _toColombiaIso(DateTime dt) {
    // Formatea el datetime con offset Colombia -05:00 explícito
    final s = dt.toIso8601String().split('.').first;
    return '$s-05:00';
  }

  Map<String, dynamic> toJson() {
    return {
      if (contextoId != null) 'contexto_id': contextoId,
      if (category != null && category!.trim().isNotEmpty) 'category': category,
      if (context != null && context!.trim().isNotEmpty) 'context': context,
      'scheduled_at': _toColombiaIso(scheduledAt),
    };
  }
}
