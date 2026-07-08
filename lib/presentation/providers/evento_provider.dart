import 'package:flutter/foundation.dart';
import '../../data/repositories/evento_repository.dart';
import '../../domain/models/evento.dart';

class EventoProvider extends ChangeNotifier {
  final EventoRepository _eventoRepo;

  EventoProvider(this._eventoRepo);

  List<Evento> _eventos = [];
  Evento? _eventoSeleccionado;
  bool _cargando = false;
  String? _error;

  List<Evento> get eventos => _eventos;
  Evento? get eventoSeleccionado => _eventoSeleccionado;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargarEventos() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _eventos = await _eventoRepo.listar();
    } catch (e) {
      _error = 'No se pudieron cargar los eventos';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarDetalle(int id) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _eventoSeleccionado = await _eventoRepo.obtener(id);
    } catch (e) {
      _error = 'No se pudo cargar el detalle del evento';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> crearEvento(Evento evento) async {
    try {
      await _eventoRepo.crear(evento);
      await cargarEventos();
      return true;
    } catch (e) {
      _error = 'No se pudo crear el evento';
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarEvento(int id, Evento evento) async {
    try {
      await _eventoRepo.actualizar(id, evento);
      await cargarEventos();
      return true;
    } catch (e) {
      _error = 'No se pudo actualizar el evento';
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarEvento(int id) async {
    try {
      await _eventoRepo.eliminar(id);
      await cargarEventos();
      return true;
    } catch (e) {
      _error = 'No se pudo eliminar el evento';
      notifyListeners();
      return false;
    }
  }

  List<Evento> filtrarPorEstado(String filtro) {
    if (filtro == 'Todos' || filtro == 'Todas') return _eventos;
    final Map<String, String> estadoPorFiltro = {
      'Próximos': 'Publicado',
      'En curso': 'EnCurso',
      'Finalizados': 'Finalizado',
    };
    final estadoBuscado = estadoPorFiltro[filtro];
    return _eventos.where((e) => e.estado == estadoBuscado).toList();
  }

  int get total => _eventos.length;
  int get proximos => _eventos.where((e) => e.estado == 'Publicado').length;
  int get enCurso => _eventos.where((e) => e.estado == 'EnCurso').length;
  int get borrador => _eventos.where((e) => e.estado == 'Borrador').length;
  int get finalizados => _eventos.where((e) => e.estado == 'Finalizado').length;

  List<Evento> eventosPorOrganizador(int? organizadorId) {
    if (organizadorId == null) return _eventos;
    return _eventos.where((e) => e.organizadorId == organizadorId).toList();
  }
}
