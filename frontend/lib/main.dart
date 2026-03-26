import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:frontend/proxy/proxy.dart';
import 'screens/home_screen.dart';
import 'app_state.dart';

void main() => runApp(buildApp());

@visibleForTesting
// Erzeugt die App mitsamt AppState, optional mit übergebenem Testzustand.
Widget buildApp({AppState? state}) {
  final appState = state ?? AppState(BackendProxy(), http.Client());
  return AppStateScope(notifier: appState, child: const MyApp());
}

// Stellt das Root-Widget samt globalem Theme bereit.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bar Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFE7F0FF),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF1E293B),
          displayColor: const Color(0xFF0F172A),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          color: colorScheme.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        searchBarTheme: SearchBarThemeData(
          elevation: const MaterialStatePropertyAll(0),
          surfaceTintColor: const MaterialStatePropertyAll(Colors.transparent),
          backgroundColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.focused)
                ? Colors.white
                : Colors.white.withOpacity(0.92),
          ),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
      ),
      home: const MyHomePage(title: ''),
    );
  }
}

// Host-Widget, das den eigentlichen HomeScreen rendert.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
