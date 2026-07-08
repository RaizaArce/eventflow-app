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
  return Scaffold(
    backgroundColor: Colors.grey.shade50,
    appBar: AppBar(
      title: Text(
        widget.participante == null
        ? 'Registrar participante'
        : 'Editar participante',
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
        padding: const EdgeInsets.all(16),
        children: [

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
                        ),
                        
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: dniController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8),
                          ],
                          decoration: InputDecoration(
                            labelText: 'DNI',
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
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: correoController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo',
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: telefonoController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(9),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Teléfono',
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
                          SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: cargando ? null : registrarParticipante,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: cargando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  widget.participante == null
                                      ? Icons.save
                                      : Icons.edit,
                                ),
                                  label: Text(
                                        cargando
                                            ? 'Guardando...'
                                            : widget.participante == null
                                                ? 'Guardar'
                                                : 'Actualizar',
                                                  ),
                                              ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              }