import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api_client.dart';
import 'crear_evento_screen.dart';

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
          Icon(icono, color: Colors.green),
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

  Widget construirBotonTemporal({
    required IconData icono,
    required String texto,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$texto se conectará en el siguiente módulo'),
            ),
          );
        },
        icon: Icon(icono),
        label: Text(texto),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detalle del evento'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : mensajeError.isNotEmpty
          ? Center(child: Text(mensajeError))
          : RefreshIndicator(
              onRefresh: cargarDetalleEvento,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.green,
                            child: Icon(
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
                            labelStyle: const TextStyle(
                              color: Colors.green,
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
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (evento == null) return;

                        final actualizado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CrearEventoScreen(evento: evento),
                          ),
                        );

                        if (actualizado == true) {
                          cargarDetalleEvento();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar evento'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  construirBotonTemporal(
                    icono: Icons.group,
                    texto: 'Ver participantes',
                  ),
                  const SizedBox(height: 10),
                  construirBotonTemporal(
                    icono: Icons.schedule,
                    texto: 'Ver agenda',
                  ),
                ],
              ),
            ),
    );
  }
}
