import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceSuggestion {
  final String description;
  final LatLng location;

  PlaceSuggestion({required this.description, required this.location});
}

class GooglePlacesService {
  final Dio _dio;

  GooglePlacesService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://nominatim.openstreetmap.org',
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );

  Future<List<PlaceSuggestion>> buscar(String input) async {
    if (input.trim().isEmpty) return [];

    final response = await _dio.get(
      '/search',
      queryParameters: {
        'q': input,
        'format': 'json',
        'limit': 5,
        'accept-language': 'es',
        'countrycodes': 'pe',
        'addressdetails': 0,
      },
      options: Options(
        headers: {'User-Agent': 'EventFlowApp/1.0'},
      ),
    );

    if (response.statusCode != 200) return [];

    final results = response.data as List?;
    if (results == null) return [];

    return results.map((r) {
      final item = r as Map<String, dynamic>;
      final lat = double.tryParse(item['lat'] as String? ?? '') ?? 0.0;
      final lng = double.tryParse(item['lon'] as String? ?? '') ?? 0.0;
      return PlaceSuggestion(
        description: item['display_name'] as String? ?? 'Sin nombre',
        location: LatLng(lat, lng),
      );
    }).toList();
  }
}
