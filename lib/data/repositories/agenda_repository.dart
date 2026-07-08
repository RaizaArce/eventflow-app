import '../../domain/models/actividad.dart';
import '../api_client.dart';

class AgendaRepository {
  final ApiClient _api;

  AgendaRepository(this._api);

  Future<List<Actividad>> listar(int eventoId) async {
    final response = await _api.dio.get('/eventos/$eventoId/agenda');
    final list = response.data as List;
    return list.map((a) => Actividad.fromJson(a)).toList();
  }

  Future<void> crear(int eventoId, Actividad actividad) async {
    await _api.dio.post(
      '/eventos/$eventoId/agenda',
      data: actividad.toJson(),
    );
  }

  Future<void> actualizar(int id, Actividad actividad) async {
    await _api.dio.put('/agenda/$id', data: actividad.toJson());
  }

  Future<void> eliminar(int id) async {
    await _api.dio.delete('/agenda/$id');
  }
}
