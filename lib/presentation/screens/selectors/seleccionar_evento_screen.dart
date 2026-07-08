import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/api_client.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/shimmer_loading.dart';
import '../participants/participantes_screen.dart';
import '../agenda/agenda_screen.dart';

class SeleccionarEventoScreen extends StatefulWidget {
  final String destino;

  const SeleccionarEventoScreen({super.key, required this.destino});

  @override
  State<SeleccionarEventoScreen> createState() =>
      _SeleccionarEventoScreenState();
}

class _SeleccionarEventoScreenState extends State<SeleccionarEventoScreen> {
  final api = ApiClient();
  List<dynamic> eventos = [];
  bool cargando = true;
  String mensajeError = '';

  @override
  void initState() {
    super.initState();
    cargarEventos();
  }

  Future<void> cargarEventos() async {
    setState(() {
      cargando = true;
      mensajeError = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      api.setToken(token);

      final response = await api.dio.get('/eventos');
      eventos = response.data;
    } catch (e) {
      mensajeError = 'No se pudieron cargar los eventos';
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  Color _colorEstado(String? estado) {
    switch (estado) {
      case 'Publicado':
        return Colors.amber.shade700;
      case 'EnCurso':
        return Colors.green;
      case 'Finalizado':
        return Colors.grey;
      case 'Borrador':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Selecciona un evento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: cargando
          ? const ShimmerCardList()
          : mensajeError.isNotEmpty
              ? Center(
                  child: Text(
                    mensajeError,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : eventos.isEmpty
                  ? const EmptyStateWidget(
                      icono: Icons.event_busy,
                      mensaje: 'No hay eventos disponibles',
                      subtitulo: 'Crea un evento primero desde la pestaña Eventos',
                    )
                  : RefreshIndicator(
                      onRefresh: cargarEventos,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: eventos.length,
                        itemBuilder: (context, index) {
                          final e = eventos[index];
                          final estado = e['estado']?.toString() ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              onTap: () {
                                final eventoId =
                                    int.parse(e['id'].toString());
                                if (widget.destino == 'participantes') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ParticipantesScreen(
                                        eventoId: eventoId,
                                      ),
                                    ),
                                  );
                                } else if (widget.destino == 'agenda') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AgendaScreen(
                                        eventoId: eventoId,
                                      ),
                                    ),
                                  );
                                }
                              },
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade700,
                                child: const Icon(
                                  Icons.event,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                e['nombre'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                e['direccion'] ?? '',
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: Chip(
                                label: Text(
                                  _labelEstado(estado),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: _colorEstado(estado),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'Publicado':
        return 'Próximo';
      case 'EnCurso':
        return 'En curso';
      case 'Finalizado':
        return 'Finalizado';
      case 'Borrador':
        return 'Borrador';
      default:
        return estado;
    }
  }
}
