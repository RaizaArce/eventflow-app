import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api_client.dart';
import 'agenda_screen.dart';

class CrearAgendaScreen extends StatefulWidget {
  final int eventoId;
  final Map<String, dynamic>? agenda; // null = crear, != null = editar

  const CrearAgendaScreen({
    super.key,
    required this.eventoId,
    this.agenda,
  });

  @override
  State<CrearAgendaScreen> createState() => _CrearAgendaScreenState();
}

class _CrearAgendaScreenState extends State<CrearAgendaScreen> {
  final api = ApiClient();
  final formKey = GlobalKey<FormState>();

  final tituloController = TextEditingController();
  final descripcionController = TextEditingController();
  final responsableController = TextEditingController();

  DateTime? horaInicio;
  DateTime? horaFin;

  bool guardando = false;

  bool get esEdicion => widget.agenda != null;

  @override
  void initState() {
    super.initState();
    precargarDatos();
  }

  void precargarDatos() {
    if (!esEdicion) return;

    final a = widget.agenda!;
    tituloController.text = a['titulo'] ?? '';
    descripcionController.text = a['descripcion'] ?? '';
    responsableController.text = a['responsable'] ?? '';

    horaInicio = DateTime.tryParse(a['hora_inicio'] ?? '');
    horaFin = DateTime.tryParse(a['hora_fin'] ?? '');
  }

  @override
  void dispose() {
    tituloController.dispose();
    descripcionController.dispose();
    responsableController.dispose();
    super.dispose();
  }

  String dos(int n) => n.toString().padLeft(2, '0');

  String formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar hora';
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} '
        '${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  String formatearApi(DateTime fecha) {
    return '${fecha.year}-${dos(fecha.month)}-${dos(fecha.day)}'
        'T${dos(fecha.hour)}:${dos(fecha.minute)}:${dos(fecha.second)}';
  }

  Future<void> seleccionarHora({required bool inicio}) async {
    final base = inicio
        ? horaInicio ?? DateTime.now()
        : horaFin ?? DateTime.now().add(const Duration(hours: 1));

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );

    if (hora == null) return;

    final nueva = DateTime(
      base.year,
      base.month,
      base.day,
      hora.hour,
      hora.minute,
    );

    setState(() {
      if (inicio) {
        horaInicio = nueva;
      } else {
        horaFin = nueva;
      }
    });
  }

  Future<void> guardar() async {
    if (!formKey.currentState!.validate()) return;

    if (horaInicio == null || horaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona horas de inicio y fin')),
      );
      return;
    }

    if (horaFin!.isBefore(horaInicio!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La hora fin debe ser mayor')),
      );
      return;
    }

    setState(() => guardando = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      api.setToken(token);

      final data = {
        'titulo': tituloController.text.trim(),
        'descripcion': descripcionController.text.trim(),
        'hora_inicio': formatearApi(horaInicio!),
        'hora_fin': formatearApi(horaFin!),
        'responsable': responsableController.text.trim(),
      };

      if (esEdicion) {
        final id = widget.agenda!['id'];
        await api.dio.put('/agenda/$id', data: data);
      } else {
        await api.dio.post(
          '/eventos/${widget.eventoId}/agenda',
          data: data,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esEdicion
                ? 'Error al actualizar actividad'
                : 'Error al crear actividad',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  InputDecoration deco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = esEdicion ? 'Editar actividad' : 'Crear actividad';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: tituloController,
              decoration: deco('Título', Icons.title),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: descripcionController,
              maxLines: 3,
              decoration: deco('Descripción', Icons.description),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: responsableController,
              decoration: deco('Responsable', Icons.person),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 20),

            InkWell(
              onTap: () => seleccionarHora(inicio: true),
              child: InputDecorator(
                decoration: deco('Hora inicio', Icons.access_time),
                child: Text(formatearFecha(horaInicio)),
              ),
            ),
            const SizedBox(height: 12),

            InkWell(
              onTap: () => seleccionarHora(inicio: false),
              child: InputDecorator(
                decoration: deco('Hora fin', Icons.access_time_filled),
                child: Text(formatearFecha(horaFin)),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: guardando ? null : guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(esEdicion ? 'Guardar cambios' : 'Crear actividad'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
