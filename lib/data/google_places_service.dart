import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceSuggestion {
  final String description;
  final LatLng location;

  PlaceSuggestion({
    required this.description,
    required this.location,
  });
}

class GooglePlacesService {
  final Dio _dio = Dio();

  // La clave
  final String _apiKey = 'AIzaSyBuNWmv5mS8gm1MITaowRj_1ddM-MBkR1Y';

  Future<List<PlaceSuggestion>> buscar(String input) async {
    if (input.trim().isEmpty) return [];

    try {
      final response = await _dio.post(
        'https://places.googleapis.com/v1/places:autocomplete',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
          },
        ),
        data: {
          "input": input,
          "includedRegionCodes": ["PE"],
          "languageCode": "es",
        },
      );

      final suggestions =
          response.data['suggestions'] as List<dynamic>? ?? [];

      List<PlaceSuggestion> resultado = [];

      for (final item in suggestions) {
        final placePrediction = item['placePrediction'];

        if (placePrediction == null) continue;

        final placeId = placePrediction['placeId'];
        final text = placePrediction['text']['text'];

        final detalle = await obtenerDetalleLugar(placeId);

        if (detalle != null) {
          resultado.add(
            PlaceSuggestion(
              description: text,
              location: detalle,
            ),
          );
        }
      }

      return resultado;

    } catch (e) {
      print("Error Places API: $e");
      return [];
    }
  }


  Future<LatLng?> obtenerDetalleLugar(String placeId) async {

    try {

      final response = await _dio.get(
        'https://places.googleapis.com/v1/places/$placeId',
        options: Options(
          headers: {
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask': 'location',
          },
        ),
      );


      final location =
          response.data['location'];

      if(location == null) return null;


      return LatLng(
        location['latitude'],
        location['longitude'],
      );


    } catch(e){
      print("Error detalle lugar: $e");
      return null;
    }

  }
}