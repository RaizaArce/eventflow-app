import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MostrarQrScreen extends StatelessWidget {
  final Map<String, dynamic> participante;

  const MostrarQrScreen({super.key, required this.participante});

  @override
  Widget build(BuildContext context) {
    final String qrData = participante['qr_code'] ?? 'sin_codigo';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Código QR de Acceso'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                participante['nombre'] ?? 'Participante',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'DNI: ${participante['dni'] ?? 'No registrado'}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250.0,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Muestre este código en el ingreso para registrar su asistencia.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}