import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../events/eventos_screen.dart';
import '../selectors/seleccionar_evento_screen.dart';
import '../profile/perfil_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int indiceActual = 0;

  final List<Widget> pantallas = [
    const DashboardScreen(),
    const EventosScreen(),
    const SeleccionarEventoScreen(destino: 'participantes'),
    const SeleccionarEventoScreen(destino: 'agenda'),
    const PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: indiceActual,
        children: pantallas,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: indiceActual,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => indiceActual = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Participantes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
