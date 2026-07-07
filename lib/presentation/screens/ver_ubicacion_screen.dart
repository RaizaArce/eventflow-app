import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class VerUbicacionScreen extends StatelessWidget {
  final double latitud;
  final double longitud;

  const VerUbicacionScreen({
    super.key,
    required this.latitud,
    required this.longitud,
  });

  @override
  Widget build(BuildContext context) {
    final posicion = LatLng(latitud, longitud);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ubicación del evento"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: posicion,
          zoom: 16,
        ),

        markers: {
          Marker(
            markerId: const MarkerId("evento"),
            position: posicion,
          ),
        },

        zoomControlsEnabled: true,
        myLocationButtonEnabled: false,
      ),
    );
  }
}