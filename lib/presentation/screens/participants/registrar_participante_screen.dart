import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/api_client.dart';
import 'package:flutter/services.dart';

class RegistrarParticipanteScreen extends StatefulWidget {
  final int eventoId;

  final Map<String, dynamic>? participante;

  const RegistrarParticipanteScreen({
    super.key,
    required this.eventoId,
    this.participante,
  });

  @override
  State<RegistrarParticipanteScreen> createState() =>
      _RegistrarParticipanteScreenState();
}

class _RegistrarParticipanteScreenState extends State<RegistrarParticipanteScreen> {
  final api = ApiClient();

  final nombreController = TextEditingController();
  final dniController = TextEditingController();
  final correoController = TextEditingController();
  final telefonoController = TextEditingController();

  bool cargando = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    if (widget.participante != null) {
      nombreController.text = widget.participante!['nombre'] ?? '';
      dniController.text = widget.participante!['dni'] ?? '';
      correoController.text = widget.participante!['correo'] ?? '';
      telefonoController.text = widget.participante!['telefono'] ?? '';
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

Future<void> registrarParticipante() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    cargando = true;
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    api.setToken(token);

    final data = {
      'nombre': nombreController.text.trim(),
      'dni': dniController.text.trim(),
      'correo': correoController.text.trim(),
      'telefono': telefonoController.text.trim(),
    };

    if (widget.participante == null) {
      await api.dio.post(
        '/eventos/${widget.eventoId}/participantes',
        data: data,
      );
    } else {
      await api.dio.put(
        '/participantes/${widget.participante!['id']}',
        data: data,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            widget.participante == null
          ? 'Participante registrado correctamente'
          : 'Participante actualizado correctamente',
          ),
        ),
      );

    Navigator.pop(context, {
      'success': true,
    });

  } catch (e) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        widget.participante == null
            ? 'Error al registrar participante\n$e'
            : 'Error al actualizar participante\n$e',
      ),
    ),
  );
}
}

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.participante != null;
    final nombre = nombreController.text;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          esEdicion ? 'Editar participante' : 'Registrar participante',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (esEdicion)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.green.shade700,
                      child: Text(
                        _iniciales(nombre),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person_outline,
                            size: 18,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Datos del participante',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: nombreController,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ ]'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese el nombre';
                        }
                        if (value.trim().length < 3) {
                          return 'Ingrese un nombre válido';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: dniController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      decoration: InputDecoration(
                        labelText: 'DNI',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese el DNI';
                        }
                        if (value.length != 8) {
                          return 'El DNI debe tener 8 dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: correoController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese el correo';
                        }
                        if (!RegExp(
                          r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                        ).hasMatch(value.trim())) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: telefonoController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese el teléfono';
                        }
                        if (value.length != 9) {
                          return 'El teléfono debe tener 9 dígitos';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: cargando ? null : registrarParticipante,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: Colors.green.shade200,
                ),
                icon: cargando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Icon(esEdicion ? Icons.edit : Icons.save, size: 22),
                label: Text(
                  cargando
                      ? 'Guardando...'
                      : esEdicion
                          ? 'Actualizar'
                          : 'Guardar',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
                              }