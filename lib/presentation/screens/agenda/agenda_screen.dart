import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/agenda_repository.dart';
import '../../../domain/models/actividad.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/shimmer_loading.dart';
import 'crear_agenda_screen.dart';

class AgendaScreen extends StatefulWidget {
  final int eventoId;

  const AgendaScreen({super.key, required this.eventoId});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  List<Actividad> agenda = [];
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
      final repo = context.read<AgendaRepository>();
      agenda = await repo.listar(widget.eventoId);
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
      final repo = context.read<AgendaRepository>();
      await repo.eliminar(id);
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
      //
      appBar: AppBar(
        title: const Text(
          'Agenda del evento',
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
      body: RefreshIndicator(
        onRefresh: cargarAgenda,
        child: cargando
            ? const ShimmerCardList()
            : error.isNotEmpty
                ? Center(child: Text(error, style: const TextStyle(color: Colors.red)))
                : agenda.isEmpty
                    ? const EmptyStateWidget(
                        icono: Icons.schedule,
                        mensaje: 'No hay actividades en la agenda',
                        subtitulo: 'Agrega la primera actividad con el botón +',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: agenda.length,
                        itemBuilder: (context, index) {
                          final a = agenda[index];
                          final isLast = index == agenda.length - 1;

                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 50,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 2,
                                        height: index == 0 ? 12 : 0,
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                      ),
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.surface,
                                            width: 2,
                                          ),
                                        ),
                                        child: const SizedBox(),
                                      ),
                                      Expanded(
                                        child: Container(
                                          width: 2,
                                          color: isLast
                                              ? Colors.transparent
                                              : Theme.of(context).colorScheme.primaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  a.titulo,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Theme.of(context).colorScheme.onSurface,
                                                    ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              PopupMenuButton(
                                                icon: Icon(
                                                  Icons.more_vert,
                                                  size: 18,
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(
                                                    value: 'editar',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit, size: 18),
                                                        SizedBox(width: 8),
                                                        Text('Editar'),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'eliminar',
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.delete, size: 18, color: Colors.red),
                                                        const SizedBox(width: 8),
                                                        const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                onSelected: (value) async {
                                                  if (value == 'eliminar') {
                                                    confirmarEliminacion(a.id!);
                                                  }
                                                  if (value == 'editar') {
                                                    final result =
                                                        await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            CrearAgendaScreen(
                                                          eventoId:
                                                              widget.eventoId,
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
                                            ],
                                          ),
                                          if (a.descripcion.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              a.descripcion,
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                fontSize: 13,
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${formatearHora(a.horaInicio?.toIso8601String() ?? '')} - ${formatearHora(a.horaFin?.toIso8601String() ?? '')}',
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.primary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (a.responsable.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                  Icon(
                                                    Icons.person,
                                                    size: 14,
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                                const SizedBox(width: 4),
                                            Flexible(
                                                child: Text(
                                                  a.responsable,
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    fontSize: 12,
                                                  ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
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
