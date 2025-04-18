import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fit_track_app/firebase_options.dart';
import 'package:fit_track_app/PT/pages/pt_login.dart'; // <- importa a página de login da PT

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PTApp());
}

class PTApp extends StatelessWidget {
  const PTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Painel da Personal Trainer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        primarySwatch: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const PTLoginPage(), // <--- login como página inicial
    );
  }
}
