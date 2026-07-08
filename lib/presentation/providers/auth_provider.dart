import 'package:flutter/foundation.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/usuario.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo;

  AuthProvider(this._authRepo);

  Usuario? _usuario;
  bool _cargando = false;
  String? _error;

  Usuario? get usuario => _usuario;
  bool get cargando => _cargando;
  bool get estaLogueado => _usuario != null;
  String? get error => _error;

  Future<void> registro(String nombre, String correo, String contrasena) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepo.registro(nombre, correo, contrasena);
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _error = 'No se pudo completar el registro';
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> login(String correo, String contrasena) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _usuario = await _authRepo.login(correo, contrasena);
      _cargando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Correo o contraseña incorrectos';
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    _usuario = null;
    notifyListeners();
  }

  Future<String> getUserName() => _authRepo.getUserName();
  Future<String> getUserRol() => _authRepo.getUserRol();
  Future<int?> getUserId() => _authRepo.getUserId();
}
