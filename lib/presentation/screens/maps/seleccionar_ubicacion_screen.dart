import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/google_places_service.dart';

class SeleccionarUbicacionScreen extends StatefulWidget {
  final double latitudInicial;
  final double longitudInicial;

  const SeleccionarUbicacionScreen({
    super.key,
    required this.latitudInicial,
    required this.longitudInicial,
  });

  @override
  State<SeleccionarUbicacionScreen> createState() =>
      _SeleccionarUbicacionScreenState();
}

class _SeleccionarUbicacionScreenState
    extends State<SeleccionarUbicacionScreen> {
  late LatLng posicionSeleccionada;
  late GoogleMapController mapaController;
  final _searchController = TextEditingController();
  final _placesService = GooglePlacesService();
  List<PlaceSuggestion> _sugerencias = [];
  String? _selectedAddress;
  bool _isSearching = false;
  Timer? _debounce;
  bool _showSugerencias = false;

  @override
  void initState() {
    super.initState();
    posicionSeleccionada = LatLng(
      widget.latitudInicial,
      widget.longitudInicial,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _sugerencias = [];
        _showSugerencias = false;
        _isSearching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      try {
        final results = await _placesService.buscar(query);
        if (!mounted) return;
        setState(() {
          _sugerencias = results;
          _showSugerencias = results.isNotEmpty;
          _isSearching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _sugerencias = [];
          _showSugerencias = false;
          _isSearching = false;
        });
      }
    });
  }

  void _seleccionarSugerencia(PlaceSuggestion suggestion) {
    setState(() {
      _showSugerencias = false;
      posicionSeleccionada = suggestion.location;
      _searchController.text = suggestion.description;
      _selectedAddress = suggestion.description;
    });
    mapaController.animateCamera(
      CameraUpdate.newLatLngZoom(suggestion.location, 16),
    );
  }

  Future<void> obtenerUbicacionActual() async {
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) return;

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.deniedForever) return;

    final posicion = await Geolocator.getCurrentPosition();
    final nuevaPosicion = LatLng(posicion.latitude, posicion.longitude);

    setState(() {
      posicionSeleccionada = nuevaPosicion;
      _searchController.clear();
      _selectedAddress = null;
      _sugerencias = [];
      _showSugerencias = false;
    });

    mapaController.animateCamera(
      CameraUpdate.newLatLngZoom(nuevaPosicion, 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Seleccionar ubicación",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                decoration: BoxDecoration(
                  color: cs.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Buscar lugar...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearching
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: cs.primary,
                                  ),
                                ),
                              )
                            : _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _sugerencias = [];
                                        _showSugerencias = false;
                                        _selectedAddress = null;
                                      });
                                    },
                                  )
                                : null,
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withAlpha(80),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    if (_selectedAddress != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: cs.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _selectedAddress!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: posicionSeleccionada,
                    zoom: 16,
                  ),
                  onMapCreated: (controller) {
                    mapaController = controller;
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId("ubicacion"),
                      position: posicionSeleccionada,
                    )
                  },
                  onTap: (LatLng nuevaPosicion) {
                    setState(() {
                      posicionSeleccionada = nuevaPosicion;
                      _searchController.clear();
                      _selectedAddress = null;
                      _sugerencias = [];
                      _showSugerencias = false;
                    });
                  },
                ),
              ),
            ],
          ),
          if (_showSugerencias)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: cs.surface,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _sugerencias.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, indent: 16, endIndent: 16, color: cs.outlineVariant),
                    itemBuilder: (context, index) {
                      final sug = _sugerencias[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.place_outlined, color: cs.primary),
                        title: Text(
                          sug.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () => _seleccionarSugerencia(sug),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "gps",
            onPressed: obtenerUbicacionActual,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "guardar",
            onPressed: () {
              Navigator.pop(context, {
                'lat': posicionSeleccionada.latitude,
                'lng': posicionSeleccionada.longitude,
              });
            },
            icon: const Icon(Icons.check),
            label: const Text("Seleccionar"),
          ),
        ],
      ),
    );
  }
}
