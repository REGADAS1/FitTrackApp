import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fit_track_app/presentation/splash/intro/pages/get_started.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.autoNavigate = true, // ⬅️ por defeito navega
    this.delay = const Duration(seconds: 3), // ⬅️ 3s
  });

  /// Se true, após [delay] navega para o GetStartedPage.
  /// Se false, mostra apenas o splash (ideal para usar no AuthGate).
  final bool autoNavigate;

  /// Duração do ecrã de splash antes de navegar (quando [autoNavigate] = true).
  final Duration delay;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoNavigate) {
      _timer = Timer(widget.delay, _goNext);
    }
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => GetStartedPage()));
  }

  @override
  void dispose() {
    _timer?.cancel(); // evita navegação após sair
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Image.asset('assets/images/adpro_white.png', width: 220),
      ),
    );
  }
}
