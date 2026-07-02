import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api_client.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final api = ApiClient();
  String nombreUsuario = '';
  List<dynamic> eventos = [];
  bool cargando = true;
  String mensajeError = '';

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() {
      cargando = true;
      mensajeError = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      nombreUsuario = prefs.getString('nombre') ?? '';

      api.setToken(token);

      final response = await api.dio.get('/eventos');
      eventos = response.data;
    } catch (e) {
      mensajeError = 'No se pudieron cargar los eventos';
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = eventos.length;
    final proximos = eventos.where((e) => e['estado'] == 'Publicado').length;
    final enCurso = eventos.where((e) => e['estado'] == 'EnCurso').length;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarDatos,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Hola, $nombreUsuario',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('Organizador', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen general',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem(Icons.event, '$total', 'Eventos'),
                        _statItem(Icons.schedule, '$proximos', 'Próximos'),
                        _statItem(
                          Icons.play_circle_outline,
                          '$enCurso',
                          'En curso',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Próximos eventos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (cargando) const Center(child: CircularProgressIndicator()),
              if (mensajeError.isNotEmpty)
                Text(mensajeError, style: const TextStyle(color: Colors.red)),
              if (!cargando && eventos.isEmpty && mensajeError.isEmpty)
                const Text('Todavía no tienes eventos creados.'),
              ...eventos.map(
                (e) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.event, color: Colors.green),
                    title: Text(e['nombre'] ?? ''),
                    subtitle: Text(
                      '${e['direccion'] ?? ''} · ${e['estado'] ?? ''}',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String numero, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          numero,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
