import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/api_client.dart';
import 'registrar_manual_screen.dart';

class EscanearAsistenciaScreen extends StatefulWidget {
  final int eventoId;

  const EscanearAsistenciaScreen({super.key, required this.eventoId});

  @override
  State<EscanearAsistenciaScreen> createState() => _EscanearAsistenciaScreenState();
}

class _EscanearAsistenciaScreenState extends State<EscanearAsistenciaScreen> {
  final api = ApiClient();
  final MobileScannerController cameraController = MobileScannerController();
  bool procesando = false;
  

  Map<String, dynamic>? resultadoExitoso;
  String? mensajeError;

  Future<void> procesarCodigoQR(String codigo) async {
    setState(() {
      procesando = true;
      resultadoExitoso = null;
      mensajeError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      api.setToken(token);

      final response = await api.dio.post(
        '/asistencias/escanear',
        data: {
          'qr_code': codigo,
          'evento_id': widget.eventoId,
        },
      );

      final data = response.data;

      if (data['valido'] == true) {
        setState(() {
          resultadoExitoso = data['participante'] ?? {
            'nombre': 'Participante Registrado',
            'dni': 'Código Válido'
          };
        });
      } else {
        setState(() {
          mensajeError = "QR inválido o no pertenece a este evento";
        });
      }
    } catch (e) {
      setState(() {
        mensajeError = "Error en el servidor o código ilegible";
      });
    } finally {
      setState(() => procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Escanear QR de Entrada',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    if (procesando || resultadoExitoso != null) return;
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      procesarCodigoQR(barcodes.first.rawValue!);
                    }
                  },
                ),
                Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: resultadoExitoso != null ? Colors.green : (mensajeError != null ? Colors.red : Colors.white),
                        width: 3
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (procesando)
                    const Center(child: CircularProgressIndicator())
                  else if (resultadoExitoso != null) ...[
                    Card(
                      color: Colors.green[100],
                      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.green, width: 1.5), borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text('¡Acceso Válido!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('${resultadoExitoso!['nombre']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('DNI: ${resultadoExitoso!['dni'] ?? ''}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setState(() => resultadoExitoso = null);
                      },
                      child: const Text('Escanear Siguiente'),
                    )
                  ] else if (mensajeError != null) ...[
                    Card(
                      color: Colors.red[100],
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(mensajeError!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => setState(() => mensajeError = null),
                      child: const Text('Reintentar Escaneo'),
                    )
                  ] else
                    const Text('Apunta al código QR de la credencial', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),

                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Registrar Asistencia Manualmente'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegistrarManualScreen(eventoId: widget.eventoId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}