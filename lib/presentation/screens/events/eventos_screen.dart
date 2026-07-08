import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/api_client.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/shimmer_loading.dart';
import 'detalle_evento_screen.dart';
import 'crear_evento_screen.dart';

class EventosScreen extends StatefulWidget {
  const EventosScreen({super.key});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  final api = ApiClient();
  List<dynamic> eventos = [];
  bool cargando = true;
  String mensajeError = '';
  String filtroSeleccionado = 'Todos';

  final filtros = ['Todos', 'Próximos', 'En curso', 'Finalizados'];

  // Mapea el filtro visual al valor real que guarda el backend
  final Map<String, String> estadoPorFiltro = {
    'Próximos': 'Publicado',
    'En curso': 'EnCurso',
    'Finalizados': 'Finalizado',
  };

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

  Color _chipColor(String? estado) {
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

  List<dynamic> get eventosFiltrados {
    if (filtroSeleccionado == 'Todos') return eventos;
    final estadoBuscado = estadoPorFiltro[filtroSeleccionado];
    return eventos.where((e) => e['estado'] == estadoBuscado).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Eventos',
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
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: filtros.map((f) {
                final seleccionado = f == filtroSeleccionado;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: seleccionado,
                    selectedColor: Colors.green.shade700,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: seleccionado ? Colors.white : Colors.black87,
                    ),
                    onSelected: (_) {
                      setState(() => filtroSeleccionado = f);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: cargarEventos,
              child: cargando
                  ? const ShimmerCardList()
                  : mensajeError.isNotEmpty
                  ? Center(child: Text(mensajeError, style: const TextStyle(color: Colors.red)))
                  : eventosFiltrados.isEmpty
                  ? const EmptyStateWidget(
                      icono: Icons.event_busy,
                      mensaje: 'No hay eventos en esta categoría',
                      subtitulo: 'Prueba cambiando el filtro o crea un nuevo evento',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: eventosFiltrados.length,
                      itemBuilder: (context, index) {
                        final e = eventosFiltrados[index];
                        final eventoId = int.parse(e['id'].toString());
                        return Hero(
                          tag: 'evento_$eventoId',
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetalleEventoScreen(
                                        eventoId: eventoId,
                                      ),
                                    ),
                                  );

                                  cargarEventos();
                                },
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green.shade700,
                                    child: const Icon(Icons.event, color: Colors.white),
                                  ),
                                  title: Text(
                                    e['nombre'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${e['direccion'] ?? ''}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  trailing: Chip(
                                    label: Text(
                                      e['estado'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: _chipColor(e['estado']),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        onPressed: () async {
          final creado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearEventoScreen()),
          );

          if (creado == true) {
            cargarEventos();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
