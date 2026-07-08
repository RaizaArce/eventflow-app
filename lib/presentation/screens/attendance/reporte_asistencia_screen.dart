import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/api_client.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/shimmer_loading.dart';

class ReporteAsistenciaScreen extends StatefulWidget {
  final int eventoId;
  const ReporteAsistenciaScreen({super.key, required this.eventoId});

  @override
  State<ReporteAsistenciaScreen> createState() => _ReporteAsistenciaScreenState();
}

class _ReporteAsistenciaScreenState extends State<ReporteAsistenciaScreen> {
  final api = ApiClient();
  Map<String, dynamic>? reporte;
  List<dynamic> listaParticipantes = [];
  List<dynamic> participantesFiltrados = [];
  final TextEditingController _searchController = TextEditingController();
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
    _searchController.addListener(_filtrarParticipantes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> cargarDatos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      api.setToken(prefs.getString('token') ?? '');

      final respuestas = await Future.wait([
        api.dio.get('/eventos/${widget.eventoId}/reporte-asistencia'),
        api.dio.get('/eventos/${widget.eventoId}/participantes'),
      ]);

      setState(() {
        reporte = respuestas[0].data;
        listaParticipantes = respuestas[1].data ?? [];
        participantesFiltrados = listaParticipantes;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  void _filtrarParticipantes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        participantesFiltrados = listaParticipantes;
      } else {
        participantesFiltrados = listaParticipantes.where((p) {
          final nombre = (p['nombre'] ?? '').toString().toLowerCase();
          final dni = (p['dni'] ?? '').toString().toLowerCase();
          return nombre.contains(query) || dni.contains(query);
        }).toList();
      }
    });
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado) {
      case 'Confirmada': return Colors.green;
      case 'Ausente': return Colors.red;
      case 'Sin registrar':
      default: return Colors.grey;
    }
  }

  IconData _obtenerIconoEstado(String estado) {
    switch (estado) {
      case 'Confirmada': return Icons.check;
      case 'Ausente': return Icons.close;
      case 'Sin registrar':
      default: return Icons.person_outline;
    }
  }

  Widget cardEstadistica(String titulo, String valor, IconData icono, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(51),
              child: Icon(icono, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Métricas de Asistencia',
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
          ? const ShimmerDetailCard()
          : reporte == null
              ? const Center(child: Text('Error al procesar el reporte de asistencia.', style: TextStyle(color: Colors.red)))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      cardEstadistica('Total Registrados', '${reporte!['total_registrados']}', Icons.people, Colors.blue),
                      const SizedBox(height: 10),
                      cardEstadistica('Asistentes Confirmados', '${reporte!['asistentes_confirmados']}', Icons.how_to_reg, Colors.green),
                      const SizedBox(height: 10),
                      cardEstadistica('Ausentes', '${reporte!['ausentes']}', Icons.person_off, Colors.red),
                      const SizedBox(height: 10),
                      cardEstadistica('Porcentaje Asistencia', '${reporte!['porcentaje_asistencia']}%', Icons.analytics, Colors.orange),
                      
                      const SizedBox(height: 25),
                      const Text(
                        'Listado de Control',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar participante por nombre o DNI...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                      const SizedBox(height: 15),
                      
                      participantesFiltrados.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.0),
                              child: EmptyStateWidget(
                                icono: Icons.people_outline,
                                mensaje: 'No se encontraron participantes',
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: participantesFiltrados.length,
                              itemBuilder: (context, index) {
                                final p = participantesFiltrados[index];
                                final String estado = p['estado_asistencia'] ?? 'Sin registrar';
                                final Color colorEstado = _obtenerColorEstado(estado);

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: colorEstado,
                                      child: Icon(
                                        _obtenerIconoEstado(estado),
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(p['nombre'] ?? 'Participante'),
                                    subtitle: Text('DNI: ${p['dni'] ?? "—"} • $estado'),
                                    trailing: estado == 'Confirmada'
                                        ? const Icon(Icons.done_all, color: Colors.green)
                                        : const Icon(Icons.more_horiz, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}