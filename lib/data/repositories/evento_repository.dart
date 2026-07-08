import '../../domain/models/evento.dart';
import '../api_client.dart';

class EventoRepository {
  final ApiClient _api;

  EventoRepository(this._api);

  Future<List<Evento>> listar() async {
    final response = await _api.dio.get('/eventos');
    final list = response.data as List;
    return list.map((e) => Evento.fromJson(e)).toList();
  }

  Future<Evento> obtener(int id) async {
    final response = await _api.dio.get('/eventos/$id');
    return Evento.fromJson(response.data);
  }

  Future<void> crear(Evento evento) async {
    await _api.dio.post('/eventos', data: evento.toJson());
  }

  Future<void> actualizar(int id, Evento evento) async {
    await _api.dio.put('/eventos/$id', data: evento.toJson());
  }

  Future<void> eliminar(int id) async {
    await _api.dio.delete('/eventos/$id');
  }
}
