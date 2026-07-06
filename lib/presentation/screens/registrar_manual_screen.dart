import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api_client.dart';

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
      final prefs = await SharedPreferences.getInstance();
      api.setToken(prefs.getString('token') ?? '');
      
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
      appBar: AppBar(title: const Text('Registro Manual')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : participantesPendientes.isEmpty
              ? const Center(child: Text('No hay participantes pendientes.'))
              : ListView.builder(
                  itemCount: participantesPendientes.length,
                  itemBuilder: (context, index) {
                    final p = participantesPendientes[index];
                    return ListTile(
                      title: Text(p['nombre'] ?? ''),
                      subtitle: Text('DNI: ${p['dni'] ?? ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.check_box_outline_blank, color: Colors.indigo),
                        onPressed: () => marcarAsistenciaManual(p['id']),
                      ),
                    );
                  },
                ),
    );
  }
}