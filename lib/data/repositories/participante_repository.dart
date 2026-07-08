import '../../domain/models/participante.dart';
import '../api_client.dart';

class ParticipanteRepository {
  final ApiClient _api;

  ParticipanteRepository(this._api);

  Future<List<Participante>> listar(int eventoId) async {
    final response = await _api.dio.get('/eventos/$eventoId/participantes');
    final list = response.data as List;
    return list.map((p) => Participante.fromJson(p)).toList();
  }

  Future<void> crear(int eventoId, Participante participante) async {
    await _api.dio.post(
      '/eventos/$eventoId/participantes',
      data: participante.toJson(),
    );
  }

  Future<void> actualizar(int id, Participante participante) async {
    await _api.dio.put('/participantes/$id', data: participante.toJson());
  }

  Future<void> eliminar(int id) async {
    await _api.dio.delete('/participantes/$id');
  }

  Future<Map<String, dynamic>> importarMasivo(int eventoId, List<Map<String, dynamic>> participantes) async {
    final response = await _api.dio.post(
      '/eventos/$eventoId/participantes/importar',
      data: {'participantes': participantes},
    );
    return response.data;
  }
}
