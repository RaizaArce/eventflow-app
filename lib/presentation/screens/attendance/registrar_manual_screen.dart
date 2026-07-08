import 'package:flutter/material.dart';
import '../../../data/api_client.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/shimmer_loading.dart';

class RegistrarManualScreen extends StatefulWidget {
  final int eventoId;
  const RegistrarManualScreen({super.key, required this.eventoId});

  @override
  State<RegistrarManualScreen> createState() => _RegistrarManualScreenState();
}

class _RegistrarManualScreenState extends State<RegistrarManualScreen> {
  final api = ApiClient();
  List<dynamic> participantesPendientes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    obtenerPendientes();
  }

  Future<void> obtenerPendientes() async {
    try {
      final response = await api.dio.get('/eventos/${widget.eventoId}/participantes');

      setState(() {
        participantesPendientes = response.data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  Future<void> marcarAsistenciaManual(int participanteId) async {
    try {
      await api.dio.post(
        '/asistencias/manual',
        data: {
          'participante_id': participanteId,
          'evento_id': widget.eventoId,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asistencia grabada manualmente'), backgroundColor: Colors.green),
      );
      obtenerPendientes();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al procesar el registro'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //
      appBar: AppBar(
        title: const Text(
          'Registro Manual',
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
          ? const ShimmerCardList()
          : participantesPendientes.isEmpty
              ? const EmptyStateWidget(
                  icono: Icons.people_outline,
                  mensaje: 'No hay participantes pendientes',
                  subtitulo: 'Registra participantes primero para marcar asistencia',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: participantesPendientes.length,
                  itemBuilder: (context, index) {
                    final p = participantesPendientes[index];
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade700,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          p['nombre'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'DNI: ${p['dni'] ?? ''}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                          onPressed: () => marcarAsistenciaManual(p['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
