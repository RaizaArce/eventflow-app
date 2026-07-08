import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icono;
  final String mensaje;
  final String? subtitulo;
  final String? accionLabel;
  final VoidCallback? onAccion;

  const EmptyStateWidget({
    super.key,
    required this.icono,
    required this.mensaje,
    this.subtitulo,
    this.accionLabel,
    this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icono, size: 50, color: Colors.green.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitulo!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            if (accionLabel != null && onAccion != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAccion,
                icon: const Icon(Icons.add, size: 20),
                label: Text(accionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
