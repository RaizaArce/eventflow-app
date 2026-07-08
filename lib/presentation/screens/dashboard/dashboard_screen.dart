import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/evento_provider.dart';
import '../events/eventos_screen.dart';
import '../events/crear_evento_screen.dart';
import '../events/detalle_evento_screen.dart';

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
    final eventosRecientes = ep.eventosRecientes.take(5).toList();

    return Scaffold(
      //
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: recargar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, $nombreUsuario',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text('Organizador', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${ep.total} eventos',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen general',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _statItem(Icons.event, '${ep.total}', 'Total')),
                          Expanded(child: _statItem(Icons.schedule, '${ep.proximos}', 'Próximos')),
                          Expanded(child: _statItem(Icons.play_circle_outline, '${ep.enCurso}', 'En curso')),
                          Expanded(child: _statItem(Icons.check_circle, '${ep.finalizados}', 'Cerrados')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Últimos eventos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventosScreen())),
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (ep.cargando)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ))
                else if (ep.error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(ep.error!, style: const TextStyle(color: Colors.red), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ),
                  )
                else if (eventosRecientes.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('Aún no hay eventos', style: TextStyle(color: Colors.grey.shade500)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Crear primer evento'),
                              onPressed: () async {
                                final creado = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CrearEventoScreen()));
                                if (creado == true && mounted) context.read<EventoProvider>().cargarEventos();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...eventosRecientes.map((e) => _buildEventCard(e)),
                const SizedBox(height: 12),
                _buildQuickActions(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleEventoScreen(eventoId: e.id!)));
          if (mounted) context.read<EventoProvider>().cargarEventos();
        },
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              if (e.imagenUrl != null && e.imagenUrl!.isNotEmpty)
                _imageCard(e.imagenUrl!)
              else
                SizedBox(
                  width: 140,
                  child: _cardPlaceholder(),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.nombre,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              e.direccion,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _estadoChip(e.estado),
                          const Spacer(),
                          Text(
                            _fecha(e.fechaInicio),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageCard(String imagenUrl) {
    try {
      return SizedBox(
        width: 140,
        child: Image.memory(
          base64Decode(imagenUrl),
          fit: BoxFit.cover,
          width: 140,
          height: 160,
          errorBuilder: (_, _, _) => _cardPlaceholder(),
        ),
      );
    } catch (_) {
      return SizedBox(width: 140, child: _cardPlaceholder());
    }
  }

  Widget _cardPlaceholder() {
    return Container(
      color: Colors.green.shade50,
      child: Center(
        child: Icon(Icons.event, size: 40, color: Colors.green.shade200),
      ),
    );
  }

  Widget _estadoChip(String? estado) {
    MaterialColor color;
    String label;
    switch (estado) {
      case 'Publicado':
        color = Colors.amber;
        label = 'Próximo';
      case 'EnCurso':
        color = Colors.green;
        label = 'En curso';
      case 'Finalizado':
        color = Colors.grey;
        label = 'Finalizado';
      case 'Borrador':
        color = Colors.blue;
        label = 'Borrador';
      default:
        color = Colors.grey;
        label = estado ?? '-';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  String _fecha(DateTime? fecha) {
    if (fecha == null) return '';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _actionChip(Icons.add_circle_outline, 'Crear', Colors.green, () async {
          final creado = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CrearEventoScreen()));
          if (creado == true && mounted) context.read<EventoProvider>().cargarEventos();
        }),
        _actionChip(Icons.calendar_month, 'Eventos', Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventosScreen()))),
        _actionChip(Icons.qr_code_scanner, 'Escanear', Colors.teal, () {
          final eventos = context.read<EventoProvider>().eventos;
          if (eventos.isEmpty) {
            _mostrarSnackbar('Primero crea un evento', Colors.orange);
            return;
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleEventoScreen(eventoId: eventos.first.id!)));
        }),
      ],
    );
  }

  Widget _actionChip(IconData icono, String label, MaterialColor color, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Icon(icono, color: color, size: 24),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(color: color.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String numero, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(numero, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  void _mostrarSnackbar(String mensaje, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [Icon(Icons.check_circle, color: Colors.white, size: 18), const SizedBox(width: 8), Flexible(child: Text(mensaje))],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
