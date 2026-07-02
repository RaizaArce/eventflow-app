import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'eventos_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int indiceActual = 0;

  final List<Widget> pantallas = const [DashboardScreen(), EventosScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pantallas[indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: indiceActual,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => indiceActual = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Eventos',
          ),
        ],
      ),
    );
  }
}
