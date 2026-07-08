class Evento {
  final int? id;
  final int organizadorId;
  final String nombre;
  final String descripcion;
  final String direccion;
  final double latitud;
  final double longitud;
  final int aforo;
  final String estado;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? cantidadParticipantes;
  final int? cantidadActividades;
  final String? imagenUrl;

  Evento({
    this.id,
    required this.organizadorId,
    required this.nombre,
    required this.descripcion,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.aforo,
    required this.estado,
    this.fechaInicio,
    this.fechaFin,
    this.cantidadParticipantes,
    this.cantidadActividades,
    this.imagenUrl,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      organizadorId: json['organizador_id'] is int
          ? json['organizador_id']
          : int.tryParse(json['organizador_id']?.toString() ?? '0') ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      direccion: json['direccion'] ?? '',
      latitud: (json['latitud'] is double)
          ? json['latitud']
          : double.tryParse(json['latitud']?.toString() ?? '0') ?? 0.0,
      longitud: (json['longitud'] is double)
          ? json['longitud']
          : double.tryParse(json['longitud']?.toString() ?? '0') ?? 0.0,
      aforo: json['aforo'] is int
          ? json['aforo']
          : int.tryParse(json['aforo']?.toString() ?? '0') ?? 0,
      estado: json['estado'] ?? '',
      fechaInicio: DateTime.tryParse(json['fecha_inicio'] ?? ''),
      fechaFin: DateTime.tryParse(json['fecha_fin'] ?? ''),
      cantidadParticipantes: json['cantidad_participantes'] is int
          ? json['cantidad_participantes']
          : int.tryParse(json['cantidad_participantes']?.toString() ?? ''),
      cantidadActividades: json['cantidad_actividades'] is int
          ? json['cantidad_actividades']
          : int.tryParse(json['cantidad_actividades']?.toString() ?? ''),
      imagenUrl: json['imagen_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'organizador_id': organizadorId,
      'nombre': nombre,
      'descripcion': descripcion,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'aforo': aforo,
      'estado': estado,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'imagen_url': imagenUrl,
    };
  }
}
