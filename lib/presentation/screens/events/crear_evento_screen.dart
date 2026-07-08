import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/api_client.dart';
import '../maps/seleccionar_ubicacion_screen.dart';

class CrearEventoScreen extends StatefulWidget {
  final Map<String, dynamic>? evento;

  const CrearEventoScreen({super.key, this.evento});

  @override
  State<CrearEventoScreen> createState() => _CrearEventoScreenState();
}

class _CrearEventoScreenState extends State<CrearEventoScreen> {
  final api = ApiClient();
  final formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final direccionController = TextEditingController();
  final aforoController = TextEditingController();
  final latitudController = TextEditingController();
  final longitudController = TextEditingController();

  DateTime? fechaInicio;
  DateTime? fechaFin;

  bool guardando = false;
  String estadoSeleccionado = 'Borrador';

  final estados = ['Borrador', 'Publicado', 'EnCurso', 'Finalizado'];

  bool get esEdicion => widget.evento != null;

  @override
  void initState() {
    super.initState();
    precargarDatosSiEsEdicion();
  }

  void precargarDatosSiEsEdicion() {
    if (!esEdicion) return;

    final evento = widget.evento!;

    nombreController.text = evento['nombre']?.toString() ?? '';
    descripcionController.text = evento['descripcion']?.toString() ?? '';
    direccionController.text = evento['direccion']?.toString() ?? '';
    aforoController.text = evento['aforo']?.toString() ?? '';

    latitudController.text = evento['latitud']?.toString() ?? '-6.77';
    longitudController.text = evento['longitud']?.toString() ?? '-79.84';

    fechaInicio = DateTime.tryParse(evento['fecha_inicio']?.toString() ?? '');
    fechaFin = DateTime.tryParse(evento['fecha_fin']?.toString() ?? '');

    final estadoActual = evento['estado']?.toString();

    if (estadoActual != null && estados.contains(estadoActual)) {
      estadoSeleccionado = estadoActual;
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    direccionController.dispose();
    aforoController.dispose();
    latitudController.dispose();
    longitudController.dispose();
    super.dispose();
  }

  String dosDigitos(int numero) {
    return numero.toString().padLeft(2, '0');
  }

  String formatearFechaVisual(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar fecha y hora';

    final dia = dosDigitos(fecha.day);
    final mes = dosDigitos(fecha.month);
    final anio = fecha.year;
    final hora = dosDigitos(fecha.hour);
    final minuto = dosDigitos(fecha.minute);

    return '$dia/$mes/$anio $hora:$minuto';
  }

  String formatearFechaApi(DateTime fecha) {
    final anio = fecha.year;
    final mes = dosDigitos(fecha.month);
    final dia = dosDigitos(fecha.day);
    final hora = dosDigitos(fecha.hour);
    final minuto = dosDigitos(fecha.minute);
    final segundo = dosDigitos(fecha.second);

    return '$anio-$mes-$dia'
        'T'
        '$hora:$minuto:$segundo';
  }

  Future<void> seleccionarFechaHora({required bool esInicio}) async {
    final fechaBase = esInicio
        ? fechaInicio ?? DateTime.now()
        : fechaFin ?? DateTime.now().add(const Duration(hours: 1));

    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: fechaBase,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (fechaSeleccionada == null || !mounted) return;

    final horaSeleccionada = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(fechaBase),
    );

    if (horaSeleccionada == null) return;

    final fechaCompleta = DateTime(
      fechaSeleccionada.year,
      fechaSeleccionada.month,
      fechaSeleccionada.day,
      horaSeleccionada.hour,
      horaSeleccionada.minute,
    );

    setState(() {
      if (esInicio) {
        fechaInicio = fechaCompleta;

        if (fechaFin == null || fechaFin!.isBefore(fechaCompleta)) {
          fechaFin = fechaCompleta.add(const Duration(hours: 1));
        }
      } else {
        fechaFin = fechaCompleta;
      }
    });
  }

  InputDecoration decoracionCampo({
    required String label,
    required IconData icono,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icono),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  String? validarCampoObligatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  Future<void> guardarEvento() async {
    if (!formKey.currentState!.validate()) return;

    if (fechaInicio == null || fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la fecha de inicio y fin del evento'),
        ),
      );
      return;
    }

    if (fechaFin!.isBefore(fechaInicio!) ||
        fechaFin!.isAtSameMomentAs(fechaInicio!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha de fin debe ser posterior a la fecha de inicio',
          ),
        ),
      );
      return;
    }

    final aforo = int.tryParse(aforoController.text.trim());
    final latitud = double.tryParse(latitudController.text.trim());
    final longitud = double.tryParse(longitudController.text.trim());

    if (aforo == null || aforo <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa un aforo válido')));
      return;
    }

    if (latitud == null || longitud == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa coordenadas válidas')),
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      api.setToken(token);

      final data = {
        'organizador_id': 1,
        'nombre': nombreController.text.trim(),
        'descripcion': descripcionController.text.trim(),
        'fecha_inicio': formatearFechaApi(fechaInicio!),
        'fecha_fin': formatearFechaApi(fechaFin!),
        'direccion': direccionController.text.trim(),
        'latitud': latitud,
        'longitud': longitud,
        'aforo': aforo,
        'estado': estadoSeleccionado,
      };

      if (esEdicion) {
        final id = widget.evento!['id'];
        await api.dio.put('/eventos/$id', data: data);
      } else {
        await api.dio.post('/eventos', data: data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esEdicion
                ? 'Evento actualizado correctamente'
                : 'Evento creado correctamente',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esEdicion
                ? 'No se pudo actualizar el evento'
                : 'No se pudo crear el evento',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  Widget construirSelectorFecha({
    required String titulo,
    required DateTime? fecha,
    required bool esInicio,
  }) {
    return InkWell(
      onTap: () => seleccionarFechaHora(esInicio: esInicio),
      child: InputDecorator(
        decoration: decoracionCampo(label: titulo, icono: Icons.calendar_today),
        child: Text(
          formatearFechaVisual(fecha),
          style: TextStyle(color: fecha == null ? Colors.grey : Colors.black87),
        ),
      ),
    );
  }

  Widget construirSelectorEstado() {
    return DropdownButtonFormField<String>(
      value: estadoSeleccionado,
      decoration: decoracionCampo(label: 'Estado', icono: Icons.flag),
      items: estados.map((estado) {
        return DropdownMenuItem<String>(value: estado, child: Text(estado));
      }).toList(),
      onChanged: (valor) {
        if (valor == null) return;
        setState(() {
          estadoSeleccionado = valor;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tituloPantalla = esEdicion ? 'Editar evento' : 'Crear evento';
    final textoBoton = esEdicion ? 'Guardar cambios' : 'Crear evento';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          tituloPantalla,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildSectionCard(
              icon: Icons.info_outline,
              titulo: 'Información del evento',
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: decoracionCampo(
                    label: 'Nombre del evento',
                    icono: Icons.event,
                  ),
                  validator: validarCampoObligatorio,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: descripcionController,
                  maxLines: 3,
                  decoration: decoracionCampo(
                    label: 'Descripción',
                    icono: Icons.description,
                  ),
                  validator: validarCampoObligatorio,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: direccionController,
                  decoration: decoracionCampo(
                    label: 'Dirección',
                    icono: Icons.location_on,
                  ),
                  validator: validarCampoObligatorio,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: aforoController,
                  keyboardType: TextInputType.number,
                  decoration: decoracionCampo(label: 'Aforo', icono: Icons.people),
                  validator: validarCampoObligatorio,
                ),
                const SizedBox(height: 14),
                construirSelectorEstado(),
              ],
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              icon: Icons.calendar_month,
              titulo: 'Fecha y hora',
              children: [
                construirSelectorFecha(
                  titulo: 'Fecha de inicio',
                  fecha: fechaInicio,
                  esInicio: true,
                ),
                const SizedBox(height: 14),
                construirSelectorFecha(
                  titulo: 'Fecha de fin',
                  fecha: fechaFin,
                  esInicio: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              icon: Icons.map_outlined,
              titulo: 'Ubicación del evento',
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text("Seleccionar ubicación"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      side: BorderSide(color: Colors.green.shade700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final latActual =
                          double.tryParse(latitudController.text) ?? -6.7714;
                      final lngActual =
                          double.tryParse(longitudController.text) ?? -79.8409;

                      final resultado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SeleccionarUbicacionScreen(
                            latitudInicial: latActual,
                            longitudInicial: lngActual,
                          ),
                        ),
                      );

                      if (resultado != null) {
                        setState(() {
                          latitudController.text =
                              resultado['lat'].toString();
                          longitudController.text =
                              resultado['lng'].toString();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Lat: ${latitudController.text}  ·  Lng: ${longitudController.text}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: guardando ? null : guardarEvento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: Colors.green.shade200,
                ),
                icon: guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 22),
                label: Text(
                  guardando ? 'Guardando...' : textoBoton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String titulo,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: Colors.green.shade700),
                ),
                const SizedBox(width: 10),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
