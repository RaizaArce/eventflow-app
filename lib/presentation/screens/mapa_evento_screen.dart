import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapaEventoScreen extends StatefulWidget {
  final double latitud;
  final double longitud;
  final String nombreEvento;

  const MapaEventoScreen({
    super.key,
    required this.latitud,
    required this.longitud,
    required this.nombreEvento,
  });

  @override
  State<MapaEventoScreen> createState() => _MapaEventoScreenState();
}

class _MapaEventoScreenState extends State<MapaEventoScreen> {
  late GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    final posicion = LatLng(widget.latitud, widget.longitud);

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
        onMapCreated: (controller) {
          mapController = controller;
        },
        markers: {
          Marker(
            markerId: const MarkerId("evento"),
            position: posicion,
            infoWindow: InfoWindow(
              title: widget.nombreEvento,
            ),
          ),
        },
      ),
    );
  }
}