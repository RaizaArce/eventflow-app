import 'package:flutter_test/flutter_test.dart';
import 'package:eventflow_app/domain/models/evento.dart';
import 'package:eventflow_app/domain/models/participante.dart';
import 'package:eventflow_app/domain/models/actividad.dart';
import 'package:eventflow_app/domain/models/usuario.dart';

void main() {
  group('Evento', () {
    test('fromJson crea instancia correctamente', () {
      final json = {
        'id': 1,
        'organizador_id': 1,
        'nombre': 'Evento Test',
        'descripcion': 'Descripción',
        'direccion': 'Av. Principal 123',
        'latitud': -6.77,
        'longitud': -79.84,
        'aforo': 100,
        'estado': 'Publicado',
        'fecha_inicio': '2026-07-10T10:00:00',
        'fecha_fin': '2026-07-10T18:00:00',
      };

      final evento = Evento.fromJson(json);

      expect(evento.id, 1);
      expect(evento.nombre, 'Evento Test');
      expect(evento.estado, 'Publicado');
      expect(evento.aforo, 100);
      expect(evento.latitud, -6.77);
      expect(evento.fechaInicio, isNotNull);
    });

    test('toJson produce mapa correcto', () {
      final evento = Evento(
        organizadorId: 1,
        nombre: 'Evento Test',
        descripcion: 'Desc',
        direccion: 'Dir',
        latitud: -6.77,
        longitud: -79.84,
        aforo: 50,
        estado: 'Borrador',
      );

      final json = evento.toJson();

      expect(json['nombre'], 'Evento Test');
      expect(json['organizador_id'], 1);
      expect(json['aforo'], 50);
      expect(json['estado'], 'Borrador');
    });

    test('fromJson maneja nulos', () {
      final json = {
        'nombre': 'Solo nombre',
        'organizador_id': null,
      };

      final evento = Evento.fromJson(json);

      expect(evento.nombre, 'Solo nombre');
      expect(evento.organizadorId, 0);
      expect(evento.aforo, 0);
    });
  });

  group('Participante', () {
    test('fromJson crea instancia correctamente', () {
      final json = {
        'id': 1,
        'nombre': 'Juan Pérez',
        'dni': '12345678',
        'correo': 'juan@test.com',
        'telefono': '987654321',
        'estado_asistencia': 'Confirmada',
        'qr_code': 'abc123',
      };

      final p = Participante.fromJson(json);

      expect(p.id, 1);
      expect(p.nombre, 'Juan Pérez');
      expect(p.dni, '12345678');
      expect(p.estadoAsistencia, 'Confirmada');
      expect(p.qrCode, 'abc123');
    });

    test('toJson no incluye id ni eventoId', () {
      final p = Participante(
        nombre: 'Ana López',
        dni: '87654321',
        correo: 'ana@test.com',
        telefono: '987123456',
      );

      final json = p.toJson();

      expect(json.containsKey('id'), false);
      expect(json['nombre'], 'Ana López');
      expect(json['dni'], '87654321');
    });
  });

  group('Actividad', () {
    test('fromJson crea instancia correctamente', () {
      final json = {
        'id': 1,
        'titulo': 'Taller de Flutter',
        'descripcion': 'Descripción del taller',
        'responsable': 'Carlos',
        'hora_inicio': '2026-07-10T10:00:00',
        'hora_fin': '2026-07-10T12:00:00',
      };

      final a = Actividad.fromJson(json);

      expect(a.id, 1);
      expect(a.titulo, 'Taller de Flutter');
      expect(a.responsable, 'Carlos');
      expect(a.horaInicio, isNotNull);
    });
  });

  group('Usuario', () {
    test('fromJson crea instancia correctamente', () {
      final json = {
        'id': 1,
        'nombre': 'Usuario Test',
        'correo': 'test@test.com',
        'token': 'jwt_token_123',
        'rol': 'Organizador',
      };

      final u = Usuario.fromJson(json);

      expect(u.nombre, 'Usuario Test');
      expect(u.token, 'jwt_token_123');
      expect(u.rol, 'Organizador');
    });

    test('fromJson usa valor por defecto para rol', () {
      final json = {
        'nombre': 'Test',
        'correo': 'test@test.com',
        'token': 'abc',
      };

      final u = Usuario.fromJson(json);

      expect(u.rol, 'Organizador');
    });
  });
}
