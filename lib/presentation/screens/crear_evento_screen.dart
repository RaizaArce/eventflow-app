import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api_client.dart';

class CrearEventoScreen extends StatefulWidget {
  const CrearEventoScreen({super.key});

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
  final latitudController = TextEditingController(text: '-6.77');
  final longitudController = TextEditingController(text: '-79.84');

  DateTime? fechaInicio;
  DateTime? fechaFin;

  bool guardando = false;

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
      border: const OutlineInputBorder(),
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
      };

      await api.dio.post('/eventos', data: data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento creado correctamente')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear el evento')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Crear evento'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Información del evento',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 20),

            const Text(
              'Fecha y hora',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

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
            const SizedBox(height: 20),

            const Text(
              'Ubicación temporal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            const Text(
              'Por ahora se usan coordenadas de prueba. Luego Javier conectará el selector de mapa.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: latitudController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: decoracionCampo(label: 'Latitud', icono: Icons.map),
              validator: validarCampoObligatorio,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: longitudController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: decoracionCampo(
                label: 'Longitud',
                icono: Icons.map_outlined,
              ),
              validator: validarCampoObligatorio,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: guardando ? null : guardarEvento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                icon: guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(guardando ? 'Guardando...' : 'Crear evento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
