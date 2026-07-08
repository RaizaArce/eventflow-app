import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/evento_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventoProvider>().cargarDetalle(widget.eventoId);
    });
  }

  Future<void> _eliminarEvento() async {
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

    final ep = context.read<EventoProvider>();
    final exito = await ep.eliminarEvento(
      widget.eventoId,
    );

    if (!mounted) return;

    if (exito) {
      _mostrarSnackbar('Evento eliminado correctamente', Colors.green);
      Navigator.pop(context, true);
    } else {
      _mostrarSnackbar('No se pudo eliminar el evento', Colors.red);
    }
  }

  void _mostrarQr(String nombreEvento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.qr_code, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                nombreEvento,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: widget.eventoId.toString(),
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.green.shade700,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ID: ${widget.eventoId}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
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

  String obtenerValor(String? valor, {String defecto = '-'}) {
    return valor ?? defecto;
  }

  String formatearFecha(String? fechaTexto) {
    if (fechaTexto == null || fechaTexto.isEmpty) return '-';
    final fecha = DateTime.tryParse(fechaTexto);
    if (fecha == null) return fechaTexto;

    String dosDigitos(int numero) => numero.toString().padLeft(2, '0');
    return '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}/${fecha.year} ${dosDigitos(fecha.hour)}:${dosDigitos(fecha.minute)}';
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
          Icon(icono, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(valor, style: TextStyle(color: Theme.of(context).colorScheme.onSurface), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerImagen(String imagenUrl) {
    try {
      final bytes = base64Decode(imagenUrl);
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              bytes,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EventoProvider>();
    final evento = ep.eventoSeleccionado;
    final cargando = ep.cargando;
    final error = ep.error;

    return Scaffold(
      //
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
          if (evento != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) async {
                switch (value) {
                  case 'editar':
                    final actualizado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CrearEventoScreen(evento: evento),
                      ),
                    );
                    if (!mounted) return;
                    if (actualizado == true) {
                      context.read<EventoProvider>().cargarDetalle(
                        widget.eventoId,
                      );
                      _mostrarSnackbar(
                        'Evento actualizado correctamente',
                        Colors.green,
                      );
                    }
                  case 'eliminar':
                    _eliminarEvento();
                  case 'qr':
                    _mostrarQr(evento.nombre);
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
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapaEventoScreen(
                          latitud: evento.latitud,
                          longitud: evento.longitud,
                          nombreEvento: evento.nombre,
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
                    title: Text('Eliminar evento',
                        style: TextStyle(color: Colors.red)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'qr',
                  child: ListTile(
                    leading: Icon(Icons.qr_code, color: Colors.green),
                    title: Text('Compartir QR'),
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
          : error != null
              ? Center(
                  child: Text(error,
                      style: const TextStyle(color: Colors.red)))
              : evento == null
                  ? const Center(child: Text('Evento no encontrado'))
                  : RefreshIndicator(
                      onRefresh: () =>
                          context.read<EventoProvider>().cargarDetalle(
                            widget.eventoId,
                          ),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (evento.imagenUrl != null && evento.imagenUrl!.isNotEmpty)
                            _bannerImagen(evento.imagenUrl!),
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
                                      child: const Icon(Icons.event,
                                          color: Colors.white, size: 30),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      evento.nombre,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Chip(
                                      label: Text(evento.estado),
                                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      labelStyle: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    construirFilaDato(
                                      icono: Icons.description,
                                      titulo: 'Descripción',
                                      valor: evento.descripcion,
                                    ),
                                    construirFilaDato(
                                      icono: Icons.calendar_today,
                                      titulo: 'Fecha de inicio',
                                      valor: formatearFecha(
                                        evento.fechaInicio?.toIso8601String(),
                                      ),
                                    ),
                                    construirFilaDato(
                                      icono: Icons.event_available,
                                      titulo: 'Fecha de fin',
                                      valor: formatearFecha(
                                        evento.fechaFin?.toIso8601String(),
                                      ),
                                    ),
                                    construirFilaDato(
                                      icono: Icons.location_on,
                                      titulo: 'Dirección',
                                      valor: evento.direccion,
                                    ),
                                    construirFilaDato(
                                      icono: Icons.people,
                                      titulo: 'Aforo',
                                      valor: '${evento.aforo}',
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
                                    valor:
                                        '${evento.cantidadParticipantes ?? 0}',
                                  ),
                                  construirFilaDato(
                                    icono: Icons.schedule,
                                    titulo: 'Actividades de agenda',
                                    valor:
                                        '${evento.cantidadActividades ?? 0}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.qr_code),
                              label: const Text('Compartir QR del evento'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green.shade700,
                                side: BorderSide(color: Colors.green.shade700),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () => _mostrarQr(evento.nombre),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }
}
