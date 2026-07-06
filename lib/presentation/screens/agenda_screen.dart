import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api_client.dart';
import 'crear_agenda_screen.dart';

class AgendaScreen extends StatefulWidget {
  final int eventoId;

  const AgendaScreen({super.key, required this.eventoId});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final api = ApiClient();

  List<dynamic> agenda = [];
  bool cargando = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    cargarAgenda();
  }

  Future<void> cargarAgenda() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      api.setToken(token);

      final response =
          await api.dio.get('/eventos/${widget.eventoId}/agenda');

      agenda = response.data;
    } catch (e) {
      error = 'No se pudo cargar la agenda';
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> eliminarActividad(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      api.setToken(token);

      await api.dio.delete('/agenda/$id');

      cargarAgenda();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la actividad')),
      );
    }
  }

  void confirmarEliminacion(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar actividad'),
        content: const Text('¿Seguro que deseas eliminar esta actividad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              eliminarActividad(id);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String formatearHora(String fechaIso) {
    try {
      final fecha = DateTime.parse(fechaIso);
      return '${fecha.hour.toString().padLeft(2, '0')}:'
          '${fecha.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fechaIso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Agenda del evento'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: cargarAgenda,
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : error.isNotEmpty
                ? Center(child: Text(error))
                : agenda.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text('No hay actividades en la agenda'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: agenda.length,
                        itemBuilder: (context, index) {
                          final a = agenda[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Icon(Icons.schedule,
                                    color: Colors.white),
                              ),
                              title: Text(
                                a['titulo'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${a['descripcion'] ?? ''}\n'
                                '${formatearHora(a['hora_inicio'] ?? '')} - '
                                '${formatearHora(a['hora_fin'] ?? '')}',
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'editar',
                                    child: Text('Editar'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'eliminar',
                                    child: Text(
                                      'Eliminar',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                                onSelected: (value) async {
                                  if (value == 'eliminar') {
                                    confirmarEliminacion(a['id']);
                                  }

                                  if (value == 'editar') {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CrearAgendaScreen(
                                          eventoId: widget.eventoId,
                                          agenda: a,
                                        ),
                                      ),
                                    );

                                    if (result == true) {
                                      cargarAgenda();
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CrearAgendaScreen(eventoId: widget.eventoId),
            ),
          );

          if (result == true) {
            cargarAgenda();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}