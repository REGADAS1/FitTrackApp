// lib/presentation/menus/cronometer.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum WorkoutState { idle, running, paused }

class CronometerPage extends StatefulWidget {
  const CronometerPage({super.key});

  @override
  State<CronometerPage> createState() => _CronometerPageState();
}

class _CronometerPageState extends State<CronometerPage>
    with TickerProviderStateMixin {
  static const Color themeBlue = Color(0xFF6EC1E4);

  WorkoutState _state = WorkoutState.idle;

  // Precisão interna em milissegundos (para arredondar segundos/minutos)
  final Stopwatch _stopwatch = Stopwatch();
  late final Ticker _ticker;
  int _elapsedMs = 0;

  // Animação do botão Play
  late final AnimationController _fadeScaleCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _fadeScaleCtrl,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _fadeScaleCtrl,
    curve: Curves.easeInOutBack,
  );

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (_state == WorkoutState.running) {
        setState(() {
          _elapsedMs = _stopwatch.elapsedMilliseconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _fadeScaleCtrl.dispose();
    super.dispose();
  }

  void _start() {
    if (_state != WorkoutState.idle) return;
    setState(() {
      _state = WorkoutState.running;
      _elapsedMs = 0;
    });
    _fadeScaleCtrl.forward();
    _stopwatch
      ..reset()
      ..start();
    _ticker.start();
  }

  void _pauseOrResume() {
    if (_state == WorkoutState.running) {
      _stopwatch.stop();
      setState(() => _state = WorkoutState.paused);
    } else if (_state == WorkoutState.paused) {
      _stopwatch.start();
      setState(() => _state = WorkoutState.running);
    }
  }

  Future<void> _stop() async {
    // NÃO paramos o cronómetro aqui; queremos que continue a contar durante o sheet.
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: false,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Já terminou?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Mostra o tempo em tempo real enquanto o sheet está aberto
              StreamBuilder<int>(
                stream: Stream.periodic(
                  const Duration(milliseconds: 100),
                  (_) => _stopwatch.elapsedMilliseconds,
                ),
                builder: (_, snap) {
                  final ms = snap.data ?? _elapsedMs;
                  return Text(
                    'Tempo registado: ${_formatHMS(ms)}',
                    style: const TextStyle(color: Colors.white70),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        'Não',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Sim',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    // Agora sim, parar e persistir
    _stopwatch.stop();
    _ticker.stop();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não autenticado — não foi possível registar.'),
          ),
        );
      }
      return;
    }

    try {
      final durationSec = (_elapsedMs / 1000).round();
      final durationMinRounded =
          (durationSec / 60).round(); // dashboard usa minutos inteiros
      final now = DateTime.now();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workout_logs')
          .add({
            'date': Timestamp.fromDate(now),
            'durationSec': durationSec,
            'durationMin': durationMinRounded,
            'source': 'cronometer',
          });

      if (mounted) {
        Navigator.pop(context, {
          'workoutLogged': true,
          'durationSec': durationSec,
          'date': now.toIso8601String(),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao registar: $e')));
      }
    }
  }

  // Formata para HH:MM:SS (sem milésimas)
  String _formatHMS(int totalMs) {
    final hours = totalMs ~/ 3600000;
    final minutes = (totalMs % 3600000) ~/ 60000;
    final seconds = (totalMs % 60000) ~/ 1000;
    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E1E), Color(0xFF111111)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Column(
              children: [
                // Título
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _state == WorkoutState.idle
                        ? 'Iniciar treino'
                        : 'Treino em curso',
                    key: ValueKey(_state),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Centro: botão Play -> cronómetro HH:MM:SS
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder:
                          (child, anim) => FadeTransition(
                            opacity: anim,
                            child: ScaleTransition(scale: anim, child: child),
                          ),
                      child:
                          _state == WorkoutState.idle
                              ? FadeTransition(
                                opacity: ReverseAnimation(_fade),
                                child: ScaleTransition(
                                  scale: Tween<double>(
                                    begin: 1.0,
                                    end: 0.85,
                                  ).animate(_scale),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: themeBlue,
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(36),
                                    ),
                                    onPressed: _start,
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 52,
                                    ),
                                  ),
                                ),
                              )
                              : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatHMS(_elapsedMs),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 54,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _state == WorkoutState.paused
                                        ? 'Em pausa'
                                        : 'A contar…',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),

                // Controlo inferior: Pausar/Retomar e Stop
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color:
                                _state == WorkoutState.idle
                                    ? Colors.white24
                                    : Colors.white38,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed:
                            _state == WorkoutState.idle ? null : _pauseOrResume,
                        icon: Icon(
                          _state == WorkoutState.paused
                              ? Icons.play_arrow
                              : Icons.pause,
                          color:
                              _state == WorkoutState.idle
                                  ? Colors.white24
                                  : Colors.white,
                        ),
                        label: Text(
                          _state == WorkoutState.paused ? 'Retomar' : 'Pausar',
                          style: TextStyle(
                            color:
                                _state == WorkoutState.idle
                                    ? Colors.white24
                                    : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _state == WorkoutState.idle ? null : _stop,
                        icon: Icon(
                          Icons.stop,
                          color:
                              _state == WorkoutState.idle
                                  ? Colors.white24
                                  : Colors.white,
                        ),
                        label: Text(
                          'Stop',
                          style: TextStyle(
                            color:
                                _state == WorkoutState.idle
                                    ? Colors.white24
                                    : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
