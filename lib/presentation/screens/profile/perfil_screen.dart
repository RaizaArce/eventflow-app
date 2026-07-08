import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/api_client.dart';
import '../auth/login_screen.dart';
import '../../widgets/empty_state_widget.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final api = ApiClient();
  String nombre = '';
  String rol = '';
  String correo = '';
  int? userId;
  List<dynamic> eventos = [];
  bool cargando = true;
  String mensajeError = '';

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  int? _userIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 0:
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
        default:
          return null;
      }
      final decoded = utf8.decode(base64.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      return map['id'] as int?;
    } catch (_) {
      return null;
    }
  }

  Future<void> cargarDatos() async {
    setState(() {
      cargando = true;
      mensajeError = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      nombre = prefs.getString('nombre') ?? 'Usuario';
      rol = prefs.getString('rol') ?? 'Organizador';
      correo = prefs.getString('correo') ?? '';

      final token = prefs.getString('token') ?? '';
      api.setToken(token);

      userId = prefs.getInt('userId');

      if (userId == null) {
        final idDesdeToken = _userIdFromToken(token);
        if (idDesdeToken != null) {
          userId = idDesdeToken;
          await prefs.setInt('userId', idDesdeToken);
        }
      }

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

  String _iniciales(String texto) {
    if (texto.isEmpty) return '?';
    final partes = texto.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
    }
    return texto[0].toUpperCase();
  }

  Future<void> cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
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
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = userId;
    final tieneOrgId =
        eventos.isNotEmpty && (eventos.first as Map).containsKey('organizador_id');

    final misEventos = (tieneOrgId && uid != null)
        ? eventos.where((e) => e['organizador_id'] == uid).toList()
        : eventos;

    final total = misEventos.length;
    final borrador = misEventos.where((e) => e['estado'] == 'Borrador').length;
    final publicados = misEventos.where((e) => e['estado'] == 'Publicado').length;
    final enCurso = misEventos.where((e) => e['estado'] == 'EnCurso').length;
    final finalizados = misEventos.where((e) => e['estado'] == 'Finalizado').length;

    final eventosRecientes =
        misEventos.length > 3 ? misEventos.sublist(0, 3) : misEventos;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: cargarDatos,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(),
            if (cargando)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (mensajeError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.red.shade100),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            mensajeError,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              _buildMyStats(
                total: total,
                borrador: borrador,
                publicados: publicados,
                enCurso: enCurso,
                finalizados: finalizados,
              ),
              _buildRecentEvents(eventosRecientes),
            ],
            _buildLogoutButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade700,
            Colors.green.shade500,
            Colors.green.shade400,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 30,
        left: 24,
        right: 24,
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white,
              child: Text(
                _iniciales(nombre),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            nombre,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              rol,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (correo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              correo,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyStats({
    required int total,
    required int borrador,
    required int publicados,
    required int enCurso,
    required int finalizados,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Icon(Icons.person, size: 20, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Mis eventos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              _statCard(Icons.event, '$total', 'Total', Colors.teal),
              _statCard(Icons.edit_note, '$borrador', 'Borrador', Colors.blue),
              _statCard(Icons.public, '$publicados', 'Publicados', Colors.amber.shade700),
              _statCard(Icons.play_circle_fill, '$enCurso', 'En curso', Colors.green.shade600),
              _statCard(Icons.check_circle, '$finalizados', 'Finalizados', Colors.grey.shade600),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String numero, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            numero,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEvents(List<dynamic> eventosRecientes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Icon(Icons.history, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                'Mis eventos recientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
        if (eventosRecientes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: EmptyStateWidget(
                icono: Icons.event_busy,
                mensaje: 'Aún no hay eventos registrados',
                subtitulo: 'Crea tu primer evento desde la pestaña Eventos',
              ),
            ),
          )
        else
          ...eventosRecientes.map(
            (e) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade700,
                  child: const Icon(Icons.event, color: Colors.white),
                ),
                title: Text(
                  e['nombre'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${e['direccion'] ?? ''} · ${e['estado'] ?? ''}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.logout, color: Colors.red, size: 22),
          ),
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: cerrarSesion,
        ),
      ),
    );
  }
}
