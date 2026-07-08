import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/evento_provider.dart';
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
  String filtroSeleccionado = 'Todos';
  String busqueda = '';

  final filtros = ['Todos', 'Próximos', 'En curso', 'Finalizados'];
  final busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventoProvider>().cargarEventos();
    });
  }

  @override
  void dispose() {
    busquedaController.dispose();
    super.dispose();
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

  Widget _avatarEvento(String? imagenUrl) {
    if (imagenUrl == null || imagenUrl.isEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.event, color: Colors.white),
      );
    }
    try {
      return CircleAvatar(
        radius: 22,
        backgroundImage: MemoryImage(base64Decode(imagenUrl)),
      );
    } catch (_) {
      return CircleAvatar(
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.event, color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EventoProvider>();
    final eventosFiltrados = ep.filtrarPorEstado(filtroSeleccionado);
    final eventosMostrados = busqueda.isEmpty
        ? eventosFiltrados
        : eventosFiltrados
            .where((e) =>
                e.nombre.toLowerCase().contains(busqueda.toLowerCase()) ||
                e.direccion.toLowerCase().contains(busqueda.toLowerCase()))
            .toList();

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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: TextField(
              controller: busquedaController,
              onChanged: (v) => setState(() => busqueda = v),
              decoration: InputDecoration(
                hintText: 'Buscar eventos...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          busquedaController.clear();
                          setState(() => busqueda = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
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
              onRefresh: () => ep.cargarEventos(),
              child: ep.cargando
                  ? const ShimmerCardList()
                  : ep.error != null
                      ? Center(
                          child: Text(ep.error!,
                              style: const TextStyle(color: Colors.red)))
                      : eventosMostrados.isEmpty
                          ? EmptyStateWidget(
                              icono: busqueda.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.event_busy,
                              mensaje: busqueda.isNotEmpty
                                  ? 'No se encontraron eventos'
                                  : 'No hay eventos en esta categoría',
                              subtitulo: busqueda.isNotEmpty
                                  ? 'Prueba con otro término de búsqueda'
                                  : 'Prueba cambiando el filtro o crea un nuevo evento',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: eventosMostrados.length,
                              itemBuilder: (context, index) {
                                final e = eventosMostrados[index];
                                return Hero(
                                  tag: 'evento_${e.id}',
                                  child: Card(
                                    margin:
                                        const EdgeInsets.only(bottom: 12),
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      child: InkWell(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  DetalleEventoScreen(
                                                eventoId: e.id!,
                                              ),
                                            ),
                                          );
                                          if (context.mounted) {
                                            context
                                                .read<EventoProvider>()
                                                .cargarEventos();
                                          }
                                        },
                                          child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          leading: _avatarEvento(e.imagenUrl),
                                          title: Text(
                                            e.nombre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(
                                            e.direccion,
                                            style: const TextStyle(
                                                color: Colors.grey),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          trailing: Chip(
                                            label: Text(
                                              e.estado,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor:
                                                _chipColor(e.estado),
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
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

          if (creado == true && context.mounted) {
            context.read<EventoProvider>().cargarEventos();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
