import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/participante_repository.dart';
import '../../../domain/models/participante.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/shimmer_loading.dart';
import 'registrar_participante_screen.dart';
import 'mostrar_qr_screen.dart';

class ParticipantesScreen extends StatefulWidget {
  final int eventoId;

  const ParticipantesScreen({
    super.key,
    required this.eventoId,
  });

  @override
  State<ParticipantesScreen> createState() => _ParticipantesScreenState();
}

class _ParticipantesScreenState extends State<ParticipantesScreen> {
  List<Participante> participantes = [];
  List<Participante> participantesFiltrados = [];
  final buscadorController = TextEditingController();

  bool cargando = true;
  String mensajeError = '';

  @override
  void initState() {
    super.initState();
    cargarParticipantes();
  }

  Future<void> cargarParticipantes() async {
    setState(() {
      cargando = true;
      mensajeError = '';
    });

    try {
      final repo = context.read<ParticipanteRepository>();
      final data = await repo.listar(widget.eventoId);
      setState(() {
        participantes = data;
        participantesFiltrados = data;
      });
    } catch (e) {
      setState(() {
        mensajeError = 'No se pudieron cargar los participantes';
      });
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  void filtrarParticipantes(String texto) {
    setState(() {
      if (texto.isEmpty) {
        participantesFiltrados = participantes;
      } else {
        participantesFiltrados = participantes.where((p) {
          final nombre = p.nombre.toLowerCase();
          final dni = p.dni.toLowerCase();
          final correo = p.correo.toLowerCase();
          final buscar = texto.toLowerCase();
          return nombre.contains(buscar) ||
              dni.contains(buscar) ||
              correo.contains(buscar);
        }).toList();
      }
    });
  }

  Future<void> confirmarEliminacion(Participante participante) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar participante'),
          content: Text(
            '¿Está seguro de eliminar a\n${participante.nombre}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      final repo = context.read<ParticipanteRepository>();
      await repo.eliminar(participante.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Participante eliminado correctamente'),
        ),
      );

      cargarParticipantes();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar participante\n$e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Participantes',
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Registrar'),
        onPressed: () async {
          final registrado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegistrarParticipanteScreen(
                eventoId: widget.eventoId,
              ),
            ),
          );

          if (registrado == true) {
            await cargarParticipantes();
          }
        },
      ),
      body: cargando
          ? const ShimmerCardList()
          : mensajeError.isNotEmpty
              ? Center(
                  child: Text(mensajeError, style: const TextStyle(color: Colors.red)),
                )
              : participantesFiltrados.isEmpty
                  ? const EmptyStateWidget(
                      icono: Icons.people_outline,
                      mensaje: 'No hay participantes registrados',
                      subtitulo: 'Registra el primer participante con el botón +',
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          child: TextField(
                            controller: buscadorController,
                            onChanged: filtrarParticipantes,
                            decoration: InputDecoration(
                              hintText: 'Buscar participante...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: participantesFiltrados.length,
                            itemBuilder: (context, index) {
                              final p = participantesFiltrados[index];
                              final iniciales = p.nombre.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase();

                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 28,
                                            backgroundColor: Colors.green.shade700,
                                            child: Text(
                                              iniciales.isNotEmpty ? iniciales : '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            p.nombre,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'DNI: ${p.dni}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 18),
                                        onSelected: (value) async {
                                          if (value == 'ver_qr') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => MostrarQrScreen(
                                                  participante: p,
                                                ),
                                              ),
                                            );
                                          }
                                          if (value == 'editar') {
                                            final actualizado = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => RegistrarParticipanteScreen(
                                                  eventoId: widget.eventoId,
                                                  participante: p,
                                                ),
                                              ),
                                            );
                                            if (actualizado == true) {
                                              await cargarParticipantes();
                                            }
                                          }
                                          if (value == 'eliminar') {
                                            confirmarEliminacion(p);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 'ver_qr',
                                            child: Row(
                                              children: [
                                                Icon(Icons.qr_code, color: Colors.green, size: 18),
                                                SizedBox(width: 8),
                                                Text('QR'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
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
                                                Icon(Icons.delete, color: Colors.red, size: 18),
                                                SizedBox(width: 8),
                                                Text('Eliminar'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}
