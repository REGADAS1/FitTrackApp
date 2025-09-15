// lib/presentation/menus/dashboard_page.dart
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_track_app/presentation/menus/chat_page.dart';
import 'package:fit_track_app/presentation/menus/user_profile_page.dart';
import 'package:fit_track_app/presentation/widgets/sidebar.dart';
import 'package:fit_track_app/presentation/menus/cronometer.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // --------- Tema / Constantes ----------
  static const themeBlue = Color(0xFF6EC1E4);
  static const bgCardOpacity = 0.06;

  // --------- Estado do utilizador ----------
  String _name = '';
  String? _profileImage;

  // Peso (mantido se precisares futuramente)
  List<Map<String, dynamic>> _weightProgress = [];

  // KPIs
  int _weeklyWorkouts = 0;
  int _weeklyMinutes = 0;
  double _weeklyWeightDelta = 0.0;
  int _streak = 0;

  // Periodização (fases)
  List<_Phase> _phases = [];
  _Phase? _currentPhase;

  // Guardar dias com atividade (peso OU treino) para streak instantâneo
  Set<DateTime> _activityDays = {};

  // Sidebar deslizante
  double _sidebarXOffset = -250;
  bool _isDragging = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  // --------- Init ----------
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadWeightProgress();
    _loadWeeklyStatsAndStreak();
    _loadPeriodization();
  }

  // --------- Loads ----------
  Future<void> _loadUserData() async {
    final user = _user;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();
      if (data != null && mounted) {
        setState(() {
          _name = data['firstName'] ?? '';
          _profileImage = data['profilePictureUrl'];
        });
      }
    }
  }

  Future<void> _loadWeightProgress() async {
    final user = _user;
    if (user != null) {
      final snapshots =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('weights')
              .orderBy('date')
              .get();

      if (!mounted) return;
      setState(() {
        _weightProgress =
            snapshots.docs.map((doc) {
              return {
                'date': (doc['date'] as Timestamp).toDate(),
                'weight': (doc['weight'] as num).toDouble(),
              };
            }).toList();
      });
    }
  }

  Future<void> _loadWeeklyStatsAndStreak() async {
    final user = _user;
    if (user == null) return;

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final workoutsSnap =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workout_logs')
            .where('date', isGreaterThanOrEqualTo: _startOfDay(weekAgo))
            .get();

    final workoutDates =
        workoutsSnap.docs
            .map((d) => (d.data()['date'] as Timestamp).toDate())
            .toList();

    final minutes = workoutsSnap.docs.fold<int>(
      0,
      (sum, d) => sum + ((d.data()['durationMin'] ?? 0) as int),
    );

    double delta = 0.0;
    if (_weightProgress.length >= 2) {
      final last = _weightProgress.last['weight'] as double;
      final nowDay = _startOfDay(now);
      final past =
          _weightProgress.reversed.firstWhere(
                (e) => (e['date'] as DateTime).isBefore(
                  nowDay.subtract(const Duration(days: 5)),
                ),
                orElse: () => _weightProgress.first,
              )['weight']
              as double;
      delta = double.parse((last - past).toStringAsFixed(1));
    }

    final doneDays = <DateTime>{};
    for (final w in _weightProgress) {
      doneDays.add(_startOfDay(w['date'] as DateTime));
    }
    for (final d in workoutDates) {
      doneDays.add(_startOfDay(d));
    }
    final streak = _calcStreak(doneDays.toList());

    if (!mounted) return;
    setState(() {
      _weeklyWorkouts = workoutDates.length;
      _weeklyMinutes = minutes;
      _weeklyWeightDelta = delta; // não exibido
      _streak = streak;
      _activityDays = doneDays;
    });
  }

  Future<void> _loadPeriodization() async {
    final user = _user;
    if (user == null) return;

    // ✅ coleção e campos corretos (iguais à PeriodizationPage)
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('periodization_phases');

    final snap = await col.orderBy('startDate').get();
    final now = DateTime.now();

    final phases = <_Phase>[];
    for (final d in snap.docs) {
      final data = d.data();
      final start = (data['startDate'] as Timestamp).toDate();
      final end = (data['endDate'] as Timestamp).toDate();

      final label =
          (data['title'] as String?)?.trim().isNotEmpty == true
              ? data['title'] as String
              : 'Fase';

      // color guardado como int na PeriodizationPage
      final colorInt = data['color'] as int?;
      final color =
          colorInt != null
              ? Color(colorInt)
              : _pickPhaseColor(label, null); // fallback

      phases.add(
        _Phase(
          start: _startOfDay(start),
          end: _startOfDay(end),
          label: label,
          color: color,
        ),
      );
    }

    // fase atual (se existir)
    _Phase? current;
    for (final p in phases) {
      if (!now.isBefore(p.start) && !now.isAfter(p.end)) {
        current = p;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _phases = phases;
      _currentPhase = current;
    });
  }

  // --------- Utils ----------
  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  int _calcStreak(List<DateTime> days) {
    if (days.isEmpty) return 0;
    days.sort((a, b) => b.compareTo(a)); // desc
    int s = 0;
    DateTime cursor = _startOfDay(DateTime.now());
    final set = days.map(_startOfDay).toSet();
    while (set.contains(cursor)) {
      s++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return s;
  }

  Color _pickPhaseColor(String label, String? hex) {
    if (hex != null && hex.trim().isNotEmpty) {
      final v = int.tryParse(hex.replaceAll('#', ''), radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    final l = label.toLowerCase();
    if (l.contains('força')) return const Color(0xFFFF9E3D); // laranja
    if (l.contains('hipertro')) return const Color(0xFFFF6EC7); // rosa
    if (l.contains('potência')) return const Color(0xFF8E7CFF); // lilás
    if (l.contains('resist')) return const Color(0xFF4DD0E1); // ciano
    return const Color(0xFF9E9E9E); // cinza
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatPage()),
    );
  }

  Future<void> _openCronometer() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CronometerPage()),
    );

    if (res is Map && res['workoutLogged'] == true) {
      final int durationSec = (res['durationSec'] as int?) ?? 0;
      final int minutesRounded = (durationSec / 60).round();

      DateTime loggedAt;
      try {
        loggedAt = DateTime.parse(res['date'] as String);
      } catch (_) {
        loggedAt = DateTime.now();
      }
      final day = _startOfDay(loggedAt);

      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final inLast7Days =
          day.isAfter(_startOfDay(weekAgo)) ||
          day.isAtSameMomentAs(_startOfDay(weekAgo));

      setState(() {
        if (inLast7Days) {
          _weeklyWorkouts += 1;
          _weeklyMinutes += minutesRounded;
        }
        _activityDays.add(day);
        _streak = _calcStreak(_activityDays.toList());
      });
    }
  }

  // --------- Queries de calendário do PT ----------
  // Evita índice composto: indexa por 'start' e filtra 'userId' em memória.

  Stream<Map<String, dynamic>?> _todayWorkoutFromCalendar() {
    final uid = _user?.uid;
    if (uid == null) return const Stream.empty();

    final start = _startOfDay(DateTime.now());
    final end = start.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('availability')
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('start', isLessThan: Timestamp.fromDate(end))
        .orderBy('start', descending: false)
        .limit(30) // margem de segurança
        .snapshots()
        .map((s) {
          // pega a primeira sessão do próprio utilizador
          for (final d in s.docs) {
            final data = d.data();
            if ((data['userId'] as String?) == uid) {
              return data;
            }
          }
          return null;
        });
  }

  Stream<Map<String, dynamic>?> _nextWorkoutFromCalendar() {
    final uid = _user?.uid;
    if (uid == null) return const Stream.empty();

    final now = DateTime.now();

    return FirebaseFirestore.instance
        .collection('availability')
        .where('start', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('start', descending: false)
        .limit(50)
        .snapshots()
        .map((s) {
          for (final d in s.docs) {
            final data = d.data();
            if ((data['userId'] as String?) == uid) {
              return data;
            }
          }
          return null;
        });
  }

  // --------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeBlue,
        child: const Icon(Icons.chat_bubble, color: Colors.white),
        onPressed: _openChat,
      ),
      body: GestureDetector(
        onHorizontalDragStart: (_) => _isDragging = true,
        onHorizontalDragUpdate: (details) {
          if (_isDragging) {
            setState(() {
              _sidebarXOffset += details.delta.dx;
              _sidebarXOffset = _sidebarXOffset.clamp(-250, 0);
            });
          }
        },
        onHorizontalDragEnd: (_) {
          _isDragging = false;
          setState(() {
            _sidebarXOffset = _sidebarXOffset > -125 ? 0 : -250;
          });
        },
        child: Stack(
          children: [
            // Fundo gradiente
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1E1E), Color(0xFF111111)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),

                      const SizedBox(height: 24),

                      // ===== 1) Hoje e Próximo treino (calendário PT) =====
                      _sectionTitle('Agenda de treinos'),
                      const SizedBox(height: 10),
                      _calendarCardsRow(),

                      const SizedBox(height: 22),

                      // ===== 2) Gráfico de Periodização =====
                      _sectionTitle('Periodização'),
                      const SizedBox(height: 6),
                      _periodizationLegend(),
                      const SizedBox(height: 10),
                      SizedBox(height: 200, child: _buildPeriodizationChart()),

                      const SizedBox(height: 22),

                      // ===== 3) KPIs + Ação =====
                      _kpiRow(),
                      const SizedBox(height: 12),
                      _quickActionsRow(),

                      const SizedBox(height: 22),

                      // ===== 4) Metas do dia =====
                      _dailyGoalsChips(),

                      const SizedBox(height: 12),

                      // ===== 5) Hidratação =====
                      _hydrationCounter(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Overlay para fechar sidebar
            if (_sidebarXOffset == 0)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _sidebarXOffset = -250),
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),

            // Sidebar animada
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: _sidebarXOffset,
              top: 0,
              bottom: 0,
              child: Sidebar(
                width: 250,
                onClose: () => setState(() => _sidebarXOffset = -250),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================= UI BLOCKS =======================

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => setState(() => _sidebarXOffset = 0),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _name.isNotEmpty ? 'Bem-vindo, $_name' : 'Bem-vindo',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GestureDetector(
          onTap:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const UserProfilePage()),
              ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            backgroundImage:
                _profileImage != null ? NetworkImage(_profileImage!) : null,
            child:
                _profileImage == null
                    ? const Icon(Icons.person, color: Colors.white, size: 28)
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  );

  // ---- Agenda (Hoje + Próximo) ----
  Widget _calendarCardsRow() {
    return Row(
      children: [
        Expanded(child: _todayWorkoutCardFromPTCalendar()),
        const SizedBox(width: 12),
        Expanded(child: _nextWorkoutCardFromPTCalendar()),
      ],
    );
  }

  Widget _calendarCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(bgCardOpacity),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _todayWorkoutCardFromPTCalendar() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('availability')
              .where(
                'start',
                isGreaterThanOrEqualTo: Timestamp.fromDate(
                  _startOfDay(DateTime.now()),
                ),
              )
              .where(
                'start',
                isLessThan: Timestamp.fromDate(
                  _startOfDay(DateTime.now()).add(const Duration(days: 1)),
                ),
              )
              .orderBy('start')
              .limit(30)
              .snapshots(),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return _calendarCard(
            title: 'Treino de hoje',
            child: const Text(
              'Erro a carregar treino de hoje.',
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }
        if (!snap.hasData) {
          return _calendarCard(
            title: 'Treino de hoje',
            child: const Text(
              'A carregar…',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final uid = _user?.uid;
        final docs = snap.data!.docs;
        Map<String, dynamic>? data;
        for (final d in docs) {
          final m = d.data();
          if ((m['userId'] as String?) == uid) {
            data = m;
            break;
          }
        }

        if (data == null) {
          return _calendarCard(
            title: 'Treino de hoje',
            child: const Text(
              'Sem sessão marcada',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final start = (data['start'] as Timestamp).toDate();
        final end = (data['end'] as Timestamp).toDate();
        final title =
            (data['title'] as String?)?.trim().isNotEmpty == true
                ? data['title'] as String
                : 'Treino';
        final when =
            '${DateFormat('HH:mm').format(start)} — ${DateFormat('HH:mm').format(end)}';

        return _calendarCard(
          title: 'Treino de hoje',
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$title • $when',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _nextWorkoutCardFromPTCalendar() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('availability')
              .where('start', isGreaterThan: Timestamp.fromDate(DateTime.now()))
              .orderBy('start')
              .limit(50)
              .snapshots(),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return _calendarCard(
            title: 'Próximo treino',
            child: const Text(
              'Erro a carregar próximo treino.',
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }
        if (!snap.hasData) {
          return _calendarCard(
            title: 'Próximo treino',
            child: const Text(
              'A carregar…',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final uid = _user?.uid;
        final docs = snap.data!.docs;

        Map<String, dynamic>? data;
        for (final d in docs) {
          final m = d.data();
          if ((m['userId'] as String?) == uid) {
            data = m;
            break;
          }
        }

        if (data == null) {
          return _calendarCard(
            title: 'Próximo treino',
            child: const Text(
              'Sem sessões futuras.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final start = (data['start'] as Timestamp).toDate();
        final title =
            (data['title'] as String?)?.trim().isNotEmpty == true
                ? data['title'] as String
                : 'Treino';
        final when = DateFormat('EEE, dd MMM HH:mm', 'pt_PT').format(start);

        return _calendarCard(
          title: 'Próximo treino',
          child: Text(
            '$title • $when',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  // ---- Periodização ----
  Widget _periodizationLegend() {
    if (_phases.isEmpty) {
      return const Text(
        'Sem fases registadas.',
        style: TextStyle(color: Colors.white70, fontSize: 13),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children:
          _phases.map((p) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: p.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Text(
                  p.label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildPeriodizationChart() {
    if (_phases.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(bgCardOpacity),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Sem dados de periodização.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    // Range global
    final globalStart = _phases
        .map((p) => p.start)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final globalEnd = _phases
        .map((p) => p.end)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final totalDays = math.max(1, globalEnd.difference(globalStart).inDays);

    // Mapa label->índice Y
    final labelToIndex = <String, double>{};
    double nextIndex = 1;
    for (final p in _phases) {
      labelToIndex.putIfAbsent(p.label, () => nextIndex++);
    }

    final bars = <LineChartBarData>[];
    for (final p in _phases) {
      final y = labelToIndex[p.label]!;
      final startX = p.start.difference(globalStart).inDays.toDouble();
      final endX = p.end.difference(globalStart).inDays.toDouble();

      final spots = <FlSpot>[];
      for (int d = startX.toInt(); d <= endX.toInt(); d++) {
        spots.add(FlSpot(d.toDouble(), y));
      }

      bars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 3,
          color: p.color,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
        ),
      );
    }

    // Bolinha no "hoje"
    final today = DateTime.now();
    final todayX =
        (today.isBefore(globalStart) || today.isAfter(globalEnd))
            ? null
            : today.difference(globalStart).inDays.toDouble();

    if (todayX != null) {
      final y =
          _currentPhase != null ? labelToIndex[_currentPhase!.label]! : 0.5;
      bars.add(
        LineChartBarData(
          spots: [FlSpot(todayX, y)],
          isCurved: false,
          barWidth: 0,
          color: Colors.transparent,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, p, bar, i) {
              return FlDotCirclePainter(
                radius: 5,
                color: Colors.white,
                strokeColor: themeBlue,
                strokeWidth: 3,
              );
            },
          ),
        ),
      );
    }

    // >>>>> Apenas INÍCIO e FIM no eixo X
    final startLabel = DateFormat('dd/MM').format(globalStart);
    final endLabel = DateFormat('dd/MM').format(globalEnd);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(bgCardOpacity),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: totalDays.toDouble(),
          minY: 0,
          maxY: (labelToIndex.length + 1).toDouble(),
          backgroundColor: Colors.transparent,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  final label =
                      labelToIndex.entries
                          .firstWhere(
                            (e) => e.value.toInt() == idx,
                            orElse: () => const MapEntry('', 0),
                          )
                          .key;
                  if (label.isEmpty) return const SizedBox.shrink();
                  return Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  );
                },
                reservedSize: 64,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: totalDays.toDouble(), // força só extremos
                getTitlesWidget: (value, meta) {
                  if (value.round() == 0) {
                    return Text(
                      startLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    );
                  }
                  if (value.round() == totalDays) {
                    return Text(
                      endLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 18,
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems:
                  (items) =>
                      items.map((s) {
                        final day = globalStart.add(
                          Duration(days: s.x.toInt()),
                        );
                        final phase = _phases.firstWhere(
                          (p) => !day.isBefore(p.start) && !day.isAfter(p.end),
                          orElse:
                              () => _Phase(
                                start: day,
                                end: day,
                                label: 'Sem fase',
                                color: Colors.grey,
                              ),
                        );
                        return LineTooltipItem(
                          '${DateFormat('dd/MM/yyyy').format(day)}\n${phase.label}',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList(),
            ),
          ),
          lineBarsData: bars,
        ),
      ),
    );
  }

  // ---- KPIs ----
  Widget _kpiRow() {
    return Row(
      children: [
        _kpiBox('Treinos da semana', '$_weeklyWorkouts'),
        const SizedBox(width: 10),
        _kpiBox('Minutos', '$_weeklyMinutes'),
        const SizedBox(width: 10),
        _periodizationKpiBox(), // <<< retângulo Periodização com datas
        const SizedBox(width: 10),
        _kpiBox('Streak', '$_streak'),
      ],
    );
  }

  Widget _kpiBox(String label, String value) => Expanded(
    child: Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(bgCardOpacity),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ],
      ),
    ),
  );

  // Caixa específica de Periodização com intervalo (dd/MM – dd/MM)
  Widget _periodizationKpiBox() {
    final name = _currentPhase?.label ?? '—';
    final d1 =
        _currentPhase != null
            ? DateFormat('dd/MM').format(_currentPhase!.start)
            : '—';
    final d2 =
        _currentPhase != null
            ? DateFormat('dd/MM').format(_currentPhase!.end)
            : '—';

    return Expanded(
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(bgCardOpacity),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$d1 – $d2',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _quickActionsRow() {
    Widget bigBtn({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeBlue,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onTap,
          child: Column(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        bigBtn(
          icon: Icons.timer,
          label: 'Iniciar treino',
          onTap: _openCronometer,
        ),
      ],
    );
  }

  // ---- Metas do dia ----
  Widget _dailyGoalsChips() {
    final user = _user;
    if (user == null) return const SizedBox.shrink();
    final key = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('daily_goals')
        .doc(key);

    final defaultGoals = {
      'beber_2l_agua': false,
      '8k_passos': false,
      'alongar_10min': false,
    };

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (ctx, snap) {
        Map<String, dynamic> goals = Map<String, dynamic>.from(defaultGoals);
        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>;
          goals.addAll(Map<String, dynamic>.from(data));
        }
        List<Widget> chips = [];
        goals.forEach((k, v) {
          chips.add(
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: FilterChip(
                label: Text(
                  _goalLabel(k),
                  style: const TextStyle(color: Colors.white),
                ),
                selected: v == true,
                backgroundColor: Colors.white.withOpacity(bgCardOpacity),
                selectedColor: themeBlue.withOpacity(0.3),
                onSelected: (sel) async {
                  await docRef.set({...goals, k: sel}, SetOptions(merge: true));
                },
                checkmarkColor: Colors.white,
              ),
            ),
          );
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Metas do dia'),
            const SizedBox(height: 8),
            Wrap(children: chips),
          ],
        );
      },
    );
  }

  String _goalLabel(String key) {
    switch (key) {
      case 'beber_2l_agua':
        return 'Beber 2L água';
      case '8k_passos':
        return '8.000 passos';
      case 'alongar_10min':
        return 'Alongar 10 min';
      default:
        return key;
    }
  }

  // ---- Hidratação ----
  Widget _hydrationCounter() {
    final user = _user;
    if (user == null) return const SizedBox.shrink();
    final key = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('hydration')
        .doc(key);

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (ctx, snap) {
        int glasses = 0;
        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>;
          glasses = (data['glasses'] ?? 0) as int;
        }
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(bgCardOpacity),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_drink, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hidratação: $glasses/8 copos',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white70),
                onPressed:
                    glasses > 0
                        ? () => docRef.set({
                          'glasses': glasses - 1,
                        }, SetOptions(merge: true))
                        : null,
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed:
                    glasses < 8
                        ? () => docRef.set({
                          'glasses': glasses + 1,
                        }, SetOptions(merge: true))
                        : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ======================= MODELOS AUXILIARES =======================

class _Phase {
  final DateTime start;
  final DateTime end;
  final String label;
  final Color color;

  _Phase({
    required this.start,
    required this.end,
    required this.label,
    required this.color,
  });
}
