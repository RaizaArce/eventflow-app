import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/api_client.dart';
import 'home_shell.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final correoCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final api = ApiClient();

  bool cargando = false;
  String mensajeError = '';

  void iniciarSesion() async {
    setState(() {
      cargando = true;
      mensajeError = '';
    });

    try {
      final data = await api.login(correoCtrl.text.trim(), passCtrl.text);

      // Guardar el token y datos del usuario localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('nombre', data['nombre']);
      await prefs.setString('rol', data['rol']);

      // Configurar el token para futuras peticiones
      api.setToken(data['token']);

      if (mounted) {
        Navigator.of( context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      }

      // Aquí luego navegaremos al Dashboard
    } catch (e) {
      setState(() {
        mensajeError = 'Correo o contraseña incorrectos';
      });
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_available, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'EventFlow',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gestiona tus eventos de forma\nsimple y efectiva',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: correoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              if (mensajeError.isNotEmpty)
                Text(mensajeError, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: cargando ? null : iniciarSesion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Iniciar Sesión',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}