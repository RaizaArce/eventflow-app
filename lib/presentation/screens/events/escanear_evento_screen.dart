import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'detalle_evento_screen.dart';

class EscanearEventoScreen extends StatefulWidget {
  const EscanearEventoScreen({super.key});

  @override
  State<EscanearEventoScreen> createState() => _EscanearEventoScreenState();
}

class _EscanearEventoScreenState extends State<EscanearEventoScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool procesando = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR de Evento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (procesando) return;

              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                final String codigoQR = barcodes.first.rawValue!.trim();

                final int? idEventoScaneado = int.tryParse(codigoQR);

                if (idEventoScaneado != null) {
                  setState(() => procesando = true);
                  cameraController.stop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetalleEventoScreen(eventoId: idEventoScaneado),
                    ),
                  );
                } else {
                  // Si el QR escaneado no es un número válido (un ID de base de datos)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Código QR inválido. Asegúrate de escanear el ID de un evento.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.teal, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (procesando)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              ),
            ),
        ],
      ),
    );
  }
}