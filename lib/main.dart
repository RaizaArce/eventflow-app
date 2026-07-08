import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'data/api_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/evento_repository.dart';
import 'data/repositories/participante_repository.dart';
import 'data/repositories/agenda_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/evento_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/auth/login_screen.dart';

void main() {
  runApp(const EventFlowApp());
}

class EventFlowApp extends StatelessWidget {
  const EventFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthRepository(api))),
        ChangeNotifierProvider(create: (_) => EventoProvider(EventoRepository(api))),
        Provider.value(value: ParticipanteRepository(api)),
        Provider.value(value: AgendaRepository(api)),
      ],
      child: _EventFlowMaterialApp(),
    );
  }
}

class _EventFlowMaterialApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final esOscuro = themeProv.esOscuro;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.green.shade700,
      brightness: esOscuro ? Brightness.dark : Brightness.light,
    );

    final inputFillColor = esOscuro ? Colors.grey.shade800 : Colors.white;
    final scaffoldBg = esOscuro ? Colors.grey.shade900 : Colors.grey.shade50;
    final cardBg = esOscuro ? Colors.grey.shade800 : null;

    return MaterialApp(
      title: 'EventFlow',
      debugShowCheckedModeBanner: false,
      themeMode: themeProv.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        brightness: colorScheme.brightness,

        textTheme: GoogleFonts.poppinsTextTheme(
          esOscuro ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        cardTheme: CardThemeData(
          elevation: 1,
          color: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green.shade700,
            side: BorderSide(color: Colors.green.shade700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.green.shade700, width: 2),
          ),
          filled: true,
          fillColor: inputFillColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),

        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.green.shade700,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          backgroundColor: cardBg ?? Colors.white,
        ),

        chipTheme: ChipThemeData(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          labelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),

        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
        ),

        scaffoldBackgroundColor: scaffoldBg,
      ),
      home: const LoginScreen(),
    );
  }
}
