import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://eventflowtdam.pythonanywhere.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  ApiClient() {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  // Registrar un nuevo usuario
  Future<Map<String, dynamic>> registro(
    String nombre,
    String correo,
    String contrasena,
  ) async {
    final response = await dio.post(
      '/auth/registro',
      data: {'nombre': nombre, 'correo': correo, 'contrasena': contrasena},
    );
    return response.data;
  }

  // Iniciar sesión
  Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    final response = await dio.post(
      '/auth/login',
      data: {'correo': correo, 'contrasena': contrasena},
    );
    return response.data;
  }

  // Configurar el token para las siguientes peticiones (una vez logueado)
  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
