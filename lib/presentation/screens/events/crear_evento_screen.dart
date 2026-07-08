import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/evento.dart';
import '../../providers/auth_provider.dart';
import '../../providers/evento_provider.dart';
import '../maps/seleccionar_ubicacion_screen.dart';

class CrearEventoScreen extends StatefulWidget {
  final Evento? evento;

  const CrearEventoScreen({super.key, this.evento});

  @override
  State<CrearEventoScreen> createState() => _CrearEventoScreenState();
}

class _CrearEventoScreenState extends State<CrearEventoScreen> {
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
  File? imagenSeleccionada;
  String? imagenBase64;

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

    nombreController.text = evento.nombre;
    descripcionController.text = evento.descripcion;
    direccionController.text = evento.direccion;
    aforoController.text = evento.aforo.toString();

    latitudController.text = evento.latitud.toString();
    longitudController.text = evento.longitud.toString();

    fechaInicio = evento.fechaInicio;
    fechaFin = evento.fechaFin;

    if (estados.contains(evento.estado)) {
      estadoSeleccionado = evento.estado;
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

  void _mostrarSnackbar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(child: Text(mensaje)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 70,
    );
    if (xfile == null) return;
    final file = File(xfile.path);
    final bytes = await file.readAsBytes();
    setState(() {
      imagenSeleccionada = file;
      imagenBase64 = base64Encode(bytes);
    });
  }

  Future<void> guardarEvento() async {
    if (!formKey.currentState!.validate()) return;

    if (fechaInicio == null || fechaFin == null) {
      _mostrarSnackbar('Selecciona la fecha de inicio y fin del evento', Colors.orange);
      return;
    }

    if (fechaFin!.isBefore(fechaInicio!) ||
        fechaFin!.isAtSameMomentAs(fechaInicio!)) {
      _mostrarSnackbar(
        'La fecha de fin debe ser posterior a la fecha de inicio',
        Colors.orange,
      );
      return;
    }

    final aforo = int.tryParse(aforoController.text.trim());
    final latitud = double.tryParse(latitudController.text.trim());
    final longitud = double.tryParse(longitudController.text.trim());

    if (aforo == null || aforo <= 0) {
      _mostrarSnackbar('Ingresa un aforo válido', Colors.orange);
      return;
    }

    if (latitud == null || longitud == null) {
      _mostrarSnackbar('Ingresa coordenadas válidas', Colors.orange);
      return;
    }

    setState(() => guardando = true);

    try {
      final organizadorId = await context.read<AuthProvider>().getUserId();
      if (organizadorId == null) {
        _mostrarSnackbar('Error al obtener datos del usuario', Colors.red);
        return;
      }

      final evento = Evento(
        organizadorId: organizadorId,
        nombre: nombreController.text.trim(),
        descripcion: descripcionController.text.trim(),
        fechaInicio: fechaInicio!,
        fechaFin: fechaFin!,
        direccion: direccionController.text.trim(),
        latitud: latitud,
        longitud: longitud,
        aforo: aforo,
        estado: estadoSeleccionado,
        imagenUrl: imagenBase64,
      );

      final ep = context.read<EventoProvider>();
      bool exito;

      if (esEdicion) {
        exito = await ep.actualizarEvento(widget.evento!.id!, evento);
      } else {
        exito = await ep.crearEvento(evento);
      }

      if (!mounted) return;

      if (exito) {
        _mostrarSnackbar(
          esEdicion
              ? 'Evento actualizado correctamente'
              : 'Evento creado correctamente',
          Colors.green,
        );
        Navigator.pop(context, true);
      } else {
        _mostrarSnackbar(
          esEdicion
              ? 'No se pudo actualizar el evento'
              : 'No se pudo crear el evento',
          Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarSnackbar(
        esEdicion
            ? 'No se pudo actualizar el evento'
            : 'No se pudo crear el evento',
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => guardando = false);
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
      initialValue: estadoSeleccionado,
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
            const SizedBox(height: 12),
            _buildSectionCard(
              icon: Icons.image,
              titulo: 'Imagen del evento',
              children: [
                GestureDetector(
                  onTap: seleccionarImagen,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: imagenSeleccionada != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              imagenSeleccionada!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('Toca para seleccionar imagen', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                  ),
                ),
                if (imagenSeleccionada != null)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Quitar imagen'),
                    onPressed: () => setState(() {
                      imagenSeleccionada = null;
                      imagenBase64 = null;
                    }),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
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
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
