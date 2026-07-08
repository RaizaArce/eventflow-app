import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/evento_provider.dart';
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
  bool get esParticipantes => widget.destino == 'participantes';
  bool get esAgenda => widget.destino == 'agenda';

  MaterialColor get colorAcento => esParticipantes ? Colors.blue : Colors.orange;
  IconData get iconoDestino => esParticipantes ? Icons.people : Icons.schedule;
  String get tituloAppBar => esParticipantes ? 'Participantes' : 'Agenda';

  Widget _avatarSelector(String? imagenUrl) {
    if (imagenUrl == null || imagenUrl.isEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: colorAcento.shade50,
        child: Icon(iconoDestino, size: 18, color: colorAcento.shade700),
      );
    }
    try {
      return CircleAvatar(
        radius: 18,
        backgroundImage: MemoryImage(base64Decode(imagenUrl)),
      );
    } catch (_) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: colorAcento.shade50,
        child: Icon(iconoDestino, size: 18, color: colorAcento.shade700),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventoProvider>().cargarEventos();
    });
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
    final ep = context.watch<EventoProvider>();
    final eventos = ep.eventos;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(iconoDestino, size: 22),
            const SizedBox(width: 8),
            Text(
              tituloAppBar,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: colorAcento.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ep.cargando
          ? const ShimmerCardList()
          : ep.error != null
              ? Center(
                  child: Text(
                    ep.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : eventos.isEmpty
                  ? EmptyStateWidget(
                      icono: iconoDestino,
                      mensaje: esParticipantes
                          ? 'No hay eventos con participantes'
                          : 'No hay eventos con agenda',
                      subtitulo: 'Selecciona un evento en la pestaña Eventos',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ep.cargarEventos(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: eventos.length,
                        itemBuilder: (context, index) {
                          final e = eventos[index];
                          final tieneInfo = esParticipantes
                              ? e.cantidadParticipantes
                              : e.cantidadActividades;
                          final previewLabel = esParticipantes
                              ? '${e.cantidadParticipantes ?? 0} participantes'
                              : '${e.cantidadActividades ?? 0} actividades';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                if (esParticipantes) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ParticipantesScreen(
                                        eventoId: e.id!,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AgendaScreen(
                                        eventoId: e.id!,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorAcento.withAlpha(25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 5,
                                        decoration: BoxDecoration(
                                          color: colorAcento.shade400,
                                          borderRadius:
                                              const BorderRadius.horizontal(
                                            left: Radius.circular(14),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  _avatarSelector(e.imagenUrl),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          e.nombre,
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 15,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                        Text(
                                                          e.direccion,
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 12,
                                                          ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Icon(
                                                    esParticipantes
                                                        ? Icons.people_outline
                                                        : Icons.event_note,
                                                    size: 16,
                                                    color: colorAcento
                                                        .shade300,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    tieneInfo != null
                                                        ? previewLabel
                                                        : 'Sin datos',
                                                    style: TextStyle(
                                                      color:
                                                          colorAcento.shade400,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Chip(
                                                    label: Text(
                                                      _labelEstado(e.estado),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        _colorEstado(
                                                            e.estado),
                                                    padding:
                                                        EdgeInsets.zero,
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    labelPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 6,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
