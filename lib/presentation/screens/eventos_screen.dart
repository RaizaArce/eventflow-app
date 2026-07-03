import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api_client.dart';
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

  List<dynamic> get eventosFiltrados {
    if (filtroSeleccionado == 'Todos') return eventos;
    final estadoBuscado = estadoPorFiltro[filtroSeleccionado];
    return eventos.where((e) => e['estado'] == estadoBuscado).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Eventos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                      color: seleccionado ? Colors.white : Colors.black,
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
                  ? const Center(child: CircularProgressIndicator())
                  : mensajeError.isNotEmpty
                  ? Center(child: Text(mensajeError))
                  : eventosFiltrados.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('No hay eventos en esta categoría')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: eventosFiltrados.length,
                      itemBuilder: (context, index) {
                        final e = eventosFiltrados[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetalleEventoScreen(
                                    eventoId: int.parse(e['id'].toString()),
                                  ),
                                ),
                              );

                              cargarEventos();
                            },
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.event, color: Colors.white),
                            ),
                            title: Text(
                              e['nombre'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${e['direccion'] ?? ''}\n${e['estado'] ?? ''}',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
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
