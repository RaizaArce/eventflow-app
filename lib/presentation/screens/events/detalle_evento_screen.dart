import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/api_client.dart';
import '../../widgets/shimmer_loading.dart';
import 'crear_evento_screen.dart';
import '../attendance/escanear_asistencia_screen.dart';
import '../attendance/reporte_asistencia_screen.dart';
import '../maps/mapa_evento_screen.dart';

class DetalleEventoScreen extends StatefulWidget {
  final int eventoId;

  const DetalleEventoScreen({super.key, required this.eventoId});

  @override
  State<DetalleEventoScreen> createState() => _DetalleEventoScreenState();
}

class _DetalleEventoScreenState extends State<DetalleEventoScreen> {
  final api = ApiClient();

  Map<String, dynamic>? evento;
  bool cargando = true;
  String mensajeError = '';

  @override
  void initState() {
    super.initState();
    cargarDetalleEvento();
  }

  Future<void> cargarDetalleEvento() async {
    setState(() {
      cargando = true;
      mensajeError = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      api.setToken(token);

      final response = await api.dio.get('/eventos/${widget.eventoId}');

      setState(() {
        evento = Map<String, dynamic>.from(response.data);
      });
    } catch (e) {
      setState(() {
        mensajeError = 'No se pudo cargar el detalle del evento';
      });
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> eliminarEvento() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Eliminar evento?'),
          content: const Text(
            'Esta acción eliminará el evento de forma permanente. ¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
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

      await api.dio.delete('/eventos/${widget.eventoId}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento eliminado correctamente')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el evento')),
      );
    }
  }

  String obtenerValor(List<String> claves, {String defecto = '-'}) {
    if (evento == null) return defecto;

    for (final clave in claves) {
      final valor = evento![clave];
      if (valor != null) {
        return valor.toString();
      }
    }

    return defecto;
  }

  String formatearFecha(String? fechaTexto) {
    if (fechaTexto == null || fechaTexto.isEmpty) return '-';

    final fecha = DateTime.tryParse(fechaTexto);
    if (fecha == null) return fechaTexto;

    String dosDigitos(int numero) => numero.toString().padLeft(2, '0');

    final dia = dosDigitos(fecha.day);
    final mes = dosDigitos(fecha.month);
    final anio = fecha.year;
    final hora = dosDigitos(fecha.hour);
    final minuto = dosDigitos(fecha.minute);

    return '$dia/$mes/$anio $hora:$minuto';
  }

  Widget construirFilaDato({
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(valor, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = obtenerValor(['nombre']);
    final descripcion = obtenerValor(['descripcion']);
    final direccion = obtenerValor(['direccion']);
    final aforo = obtenerValor(['aforo']);
    final estado = obtenerValor(['estado']);

    final fechaInicio = formatearFecha(evento?['fecha_inicio']?.toString());
    final fechaFin = formatearFecha(evento?['fecha_fin']?.toString());

    final participantes = obtenerValor([
      'cantidad_participantes',
      'participantes_count',
      'total_participantes',
    ], defecto: '0');

    final actividades = obtenerValor([
      'cantidad_actividades',
      'agenda_count',
      'total_actividades',
    ], defecto: '0');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Detalle del evento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              switch (value) {
                case 'editar':
                  if (evento == null) return;
                  final actualizado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CrearEventoScreen(evento: evento),
                    ),
                  );
                  if (actualizado == true) {
                    await cargarDetalleEvento();
                  }
                case 'eliminar':
                  eliminarEvento();
                case 'escanear':
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EscanearAsistenciaScreen(
                        eventoId: widget.eventoId,
                      ),
                    ),
                  );
                case 'reporte':
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReporteAsistenciaScreen(
                        eventoId: widget.eventoId,
                      ),
                    ),
                  );
                case 'mapa':
                  if (evento == null || !mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapaEventoScreen(
                        latitud: double.parse(
                          evento!['latitud'].toString(),
                        ),
                        longitud: double.parse(
                          evento!['longitud'].toString(),
                        ),
                        nombreEvento: evento!['nombre'].toString(),
                      ),
                    ),
                  );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'editar',
                child: ListTile(
                  leading: Icon(Icons.edit, color: Colors.green),
                  title: Text('Editar evento'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'eliminar',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Eliminar evento', style: TextStyle(color: Colors.red)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'escanear',
                child: ListTile(
                  leading: Icon(Icons.qr_code_scanner, color: Colors.blue),
                  title: Text('Escanear asistencia'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'reporte',
                child: ListTile(
                  leading: Icon(Icons.analytics_outlined, color: Colors.orange),
                  title: Text('Reporte de asistencia'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'mapa',
                child: ListTile(
                  leading: Icon(Icons.map, color: Colors.purple),
                  title: Text('Ver mapa del evento'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: cargando
          ? const ShimmerDetailCard()
          : mensajeError.isNotEmpty
          ? Center(child: Text(mensajeError, style: const TextStyle(color: Colors.red)))
          : RefreshIndicator(
              onRefresh: cargarDetalleEvento,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Hero(
                    tag: 'evento_${widget.eventoId}',
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.green.shade700,
                              child: const Icon(
                                Icons.event,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          const SizedBox(height: 14),
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(estado),
                            backgroundColor: Colors.green.shade50,
                            labelStyle: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 18),
                          construirFilaDato(
                            icono: Icons.description,
                            titulo: 'Descripción',
                            valor: descripcion,
                          ),
                          construirFilaDato(
                            icono: Icons.calendar_today,
                            titulo: 'Fecha de inicio',
                            valor: fechaInicio,
                          ),
                          construirFilaDato(
                            icono: Icons.event_available,
                            titulo: 'Fecha de fin',
                            valor: fechaFin,
                          ),
                          construirFilaDato(
                            icono: Icons.location_on,
                            titulo: 'Dirección',
                            valor: direccion,
                          ),
                          construirFilaDato(
                            icono: Icons.people,
                            titulo: 'Aforo',
                            valor: aforo,
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          construirFilaDato(
                            icono: Icons.group,
                            titulo: 'Participantes registrados',
                            valor: participantes,
                          ),
                          construirFilaDato(
                            icono: Icons.schedule,
                            titulo: 'Actividades de agenda',
                            valor: actividades,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
