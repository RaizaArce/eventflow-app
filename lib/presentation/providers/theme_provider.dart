import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get esOscuro => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _cargarPreferencia();
  }

  Future<void> _cargarPreferencia() async {
    final prefs = await SharedPreferences.getInstance();
    final esOscuro = prefs.getBool('tema_oscuro') ?? false;
    _themeMode = esOscuro ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTema() async {
    _themeMode = esOscuro ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tema_oscuro', esOscuro);
  }
}
