class Usuario {
  final int? id;
  final String nombre;
  final String correo;
  final String token;
  final String rol;

  Usuario({
    this.id,
    required this.nombre,
    required this.correo,
    required this.token,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      token: json['token'] ?? '',
      rol: json['rol'] ?? 'Organizador',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'correo': correo,
      'token': token,
      'rol': rol,
    };
  }
}
