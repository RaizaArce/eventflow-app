class Participante {
  final int? id;
  final int? eventoId;
  final String nombre;
  final String dni;
  final String correo;
  final String telefono;
  final String? estadoAsistencia;
  final String? qrCode;

  Participante({
    this.id,
    this.eventoId,
    required this.nombre,
    required this.dni,
    required this.correo,
    required this.telefono,
    this.estadoAsistencia,
    this.qrCode,
  });

  factory Participante.fromJson(Map<String, dynamic> json) {
    return Participante(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      eventoId: json['evento_id'] is int
          ? json['evento_id']
          : int.tryParse(json['evento_id']?.toString() ?? ''),
      nombre: json['nombre'] ?? '',
      dni: json['dni'] ?? '',
      correo: json['correo'] ?? '',
      telefono: json['telefono'] ?? '',
      estadoAsistencia: json['estado_asistencia'],
      qrCode: json['qr_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'dni': dni,
      'correo': correo,
      'telefono': telefono,
    };
  }
}
