import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/usuario.dart';
import '../api_client.dart';

class AuthRepository {
  final ApiClient _api;

  AuthRepository(this._api);

  Future<Usuario> login(String correo, String contrasena) async {
    final response = await _api.dio.post(
      '/auth/login',
      data: {'correo': correo, 'contrasena': contrasena},
    );
    final usuario = Usuario.fromJson(response.data);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', usuario.token);
    await prefs.setString('nombre', usuario.nombre);
    await prefs.setString('rol', usuario.rol);
    if (usuario.id != null) {
      await prefs.setInt('userId', usuario.id!);
    }
    return usuario;
  }

  Future<void> registro(String nombre, String correo, String contrasena) async {
    await _api.dio.post(
      '/auth/registro',
      data: {'nombre': nombre, 'correo': correo, 'contrasena': contrasena},
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');
    if (userId != null) return userId;

    final token = prefs.getString('token');
    if (token == null || token.isEmpty) return null;

    userId = _userIdFromToken(token);
    if (userId != null) {
      await prefs.setInt('userId', userId);
    }
    return userId;
  }

  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nombre') ?? 'Usuario';
  }

  Future<String> getUserRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rol') ?? 'Organizador';
  }

  int? _userIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 0:
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
        default:
          return null;
      }
      final decoded = utf8.decode(base64.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      return map['id'] as int?;
    } catch (_) {
      return null;
    }
  }
}
