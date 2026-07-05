import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registrar_participante_screen.dart';
import 'mostrar_qr_screen.dart';

import '../../data/api_client.dart';

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
  final api = ApiClient();

  List<dynamic> participantes = [];
  List<dynamic> participantesFiltrados = [];
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    api.setToken(token);

    final response = await api.dio.get(
      '/eventos/${widget.eventoId}/participantes',
    );

    setState(() {
      participantes = List<dynamic>.from(response.data);
      participantesFiltrados = participantes;
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
        final nombre = (p['nombre'] ?? '').toString().toLowerCase();
        final dni = (p['dni'] ?? '').toString().toLowerCase();
        final correo = (p['correo'] ?? '').toString().toLowerCase();

        final buscar = texto.toLowerCase();

        return nombre.contains(buscar) ||
            dni.contains(buscar) ||
            correo.contains(buscar);
      }).toList();
    }
  });
}

Future<void> confirmarEliminacion(
    Map<String, dynamic> participante) async {

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Eliminar participante'),
        content: Text(
          '¿Está seguro de eliminar a\n${participante['nombre']}?',
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    api.setToken(token);

    await api.dio.delete(
      '/participantes/${participante['id']}',
    );

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
    appBar: AppBar(
      title: const Text('Participantes'),
    ),

    floatingActionButton: FloatingActionButton.extended(
      backgroundColor: Colors.green,
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

        if (registrado != null && registrado['success'] == true) {
          await cargarParticipantes();
          }
      },
    ),

    body: cargando
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : mensajeError.isNotEmpty
            ? Center(
                child: Text(mensajeError),
              )
            : participantesFiltrados.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_off,
                          size: 70,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 15),
                        Text(
                          'No hay participantes registrados',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: ListView.builder(
                          itemCount: participantesFiltrados.length,
                          itemBuilder: (context, index) {
                            final participante = participantesFiltrados[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  participante['nombre'] ?? '',
                                ),
                                subtitle: Text(
                                  'DNI: ${participante['dni'] ?? ''}',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'ver_qr'){
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MostrarQrScreen(participante: participante),
                                        ),
                                      );
                                    }
                                    if (value == 'editar') {
                                      final actualizado = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RegistrarParticipanteScreen(
                                            eventoId: widget.eventoId,
                                            participante: participante,
                                          ),
                                        ),
                                      );

                                      if (actualizado != null && actualizado['success'] == true) {
                                        await cargarParticipantes();
                                      }
                                    }

                                    if (value == 'eliminar') {
                                      confirmarEliminacion(participante);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'ver_qr',
                                      child: Row(
                                        children: [
                                          Icon(Icons.qr_code, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('Ver Código QR'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'editar',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'eliminar',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Eliminar'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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

