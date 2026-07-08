class Actividad {
  final int? id;
  final int? eventoId;
  final String titulo;
  final String descripcion;
  final String responsable;
  final DateTime? horaInicio;
  final DateTime? horaFin;

  Actividad({
    this.id,
    this.eventoId,
    required this.titulo,
    required this.descripcion,
    required this.responsable,
    this.horaInicio,
    this.horaFin,
  });

  factory Actividad.fromJson(Map<String, dynamic> json) {
    return Actividad(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      eventoId: json['evento_id'] is int
          ? json['evento_id']
          : int.tryParse(json['evento_id']?.toString() ?? ''),
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      responsable: json['responsable'] ?? '',
      horaInicio: DateTime.tryParse(json['hora_inicio'] ?? ''),
      horaFin: DateTime.tryParse(json['hora_fin'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'responsable': responsable,
      'hora_inicio': horaInicio?.toIso8601String(),
      'hora_fin': horaFin?.toIso8601String(),
    };
  }
}
