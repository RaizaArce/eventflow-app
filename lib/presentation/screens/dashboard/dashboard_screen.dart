import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/evento_provider.dart';
import '../events/eventos_screen.dart';
import '../events/crear_evento_screen.dart';
import '../selectors/seleccionar_evento_screen.dart';
import '../attendance/escanear_asistencia_screen.dart';
import '../profile/perfil_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String nombreUsuario = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    nombreUsuario = await auth.getUserName();
    if (mounted) setState(() {});
    context.read<EventoProvider>().cargarEventos();
  }

  Future<void> recargar() async {
    await context.read<EventoProvider>().cargarEventos();
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EventoProvider>();
    final eventos = ep.eventos;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: recargar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: Colors.green.shade700,
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
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem(Icons.event, '${ep.total}', 'Eventos'),
                          _statItem(Icons.schedule, '${ep.proximos}', 'Próximos'),
                          _statItem(
                            Icons.play_circle_outline,
                            '${ep.enCurso}',
                            'En curso',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Acceso rápido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildQuickActionGrid(eventos),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionGrid(List eventos) {
    final actions = [
      _Accion(
        icono: Icons.add_circle_outline,
        color: Colors.green,
        titulo: 'Crear evento',
        subtitulo: 'Nuevo evento desde cero',
        onTap: () async {
          final creado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearEventoScreen()),
          );
          if (creado == true && mounted) {
            context.read<EventoProvider>().cargarEventos();
            _mostrarSnackbar('Evento creado correctamente', Colors.green);
          }
        },
      ),
      _Accion(
        icono: Icons.calendar_month,
        color: Colors.blue,
        titulo: 'Mis eventos',
        subtitulo: '${eventos.length} evento${eventos.length == 1 ? '' : 's'}',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventosScreen()),
          );
        },
      ),
      _Accion(
        icono: Icons.people_outline,
        color: Colors.orange,
        titulo: 'Participantes',
        subtitulo: 'Gestiona asistentes',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SeleccionarEventoScreen(destino: 'participantes'),
            ),
          );
        },
      ),
      _Accion(
        icono: Icons.event_note,
        color: Colors.purple,
        titulo: 'Agenda',
        subtitulo: 'Actividades del evento',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SeleccionarEventoScreen(destino: 'agenda'),
            ),
          );
        },
      ),
      _Accion(
        icono: Icons.qr_code_scanner,
        color: Colors.teal,
        titulo: 'Escanear QR',
        subtitulo: 'Registrar asistencia',
        onTap: () {
          if (eventos.isEmpty) {
            _mostrarSnackbar('Primero crea un evento', Colors.orange);
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EscanearAsistenciaScreen(
                eventoId: eventos.first.id!,
              ),
            ),
          );
        },
      ),
      _Accion(
        icono: Icons.person_outline,
        color: Colors.indigo,
        titulo: 'Mi perfil',
        subtitulo: 'Estadísticas y configuración',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PerfilScreen()),
          );
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) => _buildCard(actions[index]),
    );
  }

  Widget _buildCard(_Accion accion) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: accion.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accion.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(accion.icono, color: accion.color, size: 22),
              ),
              const Spacer(),
              Text(
                accion.titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                accion.subtitulo,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
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

  void _mostrarSnackbar(String mensaje, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(mensaje),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _Accion {
  final IconData icono;
  final Color color;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  _Accion({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });
}
