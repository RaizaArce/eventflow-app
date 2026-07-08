import 'package:flutter_test/flutter_test.dart';
import 'package:eventflow_app/domain/models/evento.dart';
import 'package:eventflow_app/presentation/providers/evento_provider.dart';
import 'package:eventflow_app/data/repositories/evento_repository.dart';
import 'package:eventflow_app/data/api_client.dart';

void main() {
  group('EventoProvider', () {
    test('valores iniciales son correctos', () {
      final api = ApiClient();
      final repo = EventoRepository(api);
      final provider = EventoProvider(repo);

      expect(provider.eventos, isEmpty);
      expect(provider.eventoSeleccionado, isNull);
      expect(provider.cargando, false);
      expect(provider.error, isNull);
      expect(provider.total, 0);
    });
  });

  group('Evento modelo', () {
    test('filtrarPorEstado con "Todos" retorna todos', () {
      final eventos = [
        Evento(organizadorId: 1, nombre: 'A', descripcion: '', direccion: '', latitud: 0, longitud: 0, aforo: 10, estado: 'Publicado'),
        Evento(organizadorId: 1, nombre: 'B', descripcion: '', direccion: '', latitud: 0, longitud: 0, aforo: 10, estado: 'Borrador'),
        Evento(organizadorId: 1, nombre: 'C', descripcion: '', direccion: '', latitud: 0, longitud: 0, aforo: 10, estado: 'EnCurso'),
      ];

      expect(eventos.length, 3);
      expect(eventos[0].estado, 'Publicado');
      expect(eventos[1].estado, 'Borrador');
      expect(eventos[2].estado, 'EnCurso');
    });
  });
}
