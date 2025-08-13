// lib/presentation/menus/dashboard_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_track_app/presentation/menus/chat_page.dart';
import 'package:fit_track_app/presentation/menus/user_profile_page.dart';
import 'package:fit_track_app/presentation/widgets/sidebar.dart';
// import 'package:fit_track_app/presentation/menus/set_training_plan.dart'; // (não usado neste ecrã)
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
  String _name = '';
  String? _profileImage;
  List<Map<String, dynamic>> _weightProgress = [];

  // Dashboard extras
  int _weeklyWorkouts = 0;
  int _weeklyMinutes = 0;
  double _weeklyWeightDelta = 0.0;
  int _streak = 0;

  // Guardar dias com atividade (peso OU treino) para streak instantâneo
  Set<DateTime> _activityDays = {};

  double _sidebarXOffset = -250;
  bool _isDragging = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadWeightProgress();
    _loadWeeklyStatsAndStreak();
  }

  Future<void> _loadUserData() async {
    final user = _user;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();
      if (data != null) {
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

    // weekly weight delta (last weight vs weight ~7-10 dias atrás)
    double delta = 0.0;
    if (_weightProgress.length >= 2) {
      final last = _weightProgress.last['weight'] as double;
      final past =
          _weightProgress.reversed.firstWhere(
                (e) => (e['date'] as DateTime).isBefore(
                  _startOfDay(now).subtract(const Duration(days: 5)),
                ),
                orElse: () => _weightProgress.first,
              )['weight']
              as double;
      delta = double.parse((last - past).toStringAsFixed(1));
    }

    // streak: dias com peso OU treino
    final doneDays = <DateTime>{};
    for (final w in _weightProgress) {
      doneDays.add(_startOfDay(w['date'] as DateTime));
    }
    for (final d in workoutDates) {
      doneDays.add(_startOfDay(d));
    }
    final streak = _calcStreak(doneDays.toList());

    if (mounted) {
      setState(() {
        _weeklyWorkouts = workoutDates.length;
        _weeklyMinutes = minutes;
        _weeklyWeightDelta = delta;
        _streak = streak;
        _activityDays = doneDays; // manter cache para updates instantâneos
      });
    }
  }

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

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatPage()),
    );
  }

  // --------- Novo: abrir cronómetro e atualizar KPIs no regresso ---------
  Future<void> _openCronometer() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CronometerPage()),
    );

    if (res is Map && res['workoutLogged'] == true) {
      // duração em segundos -> minutos arredondados
      final int durationSec = (res['durationSec'] as int?) ?? 0;
      final int minutesRounded = (durationSec / 60).round();

      // data do treino (ISO) -> dia (startOfDay)
      DateTime loggedAt;
      try {
        loggedAt = DateTime.parse(res['date'] as String);
      } catch (_) {
        loggedAt = DateTime.now();
      }
      final day = _startOfDay(loggedAt);

      // rolling window de 7 dias (como o teu query)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final inLast7Days =
          day.isAfter(_startOfDay(weekAgo)) ||
          day.isAtSameMomentAs(_startOfDay(weekAgo));

      setState(() {
        if (inLast7Days) {
          _weeklyWorkouts += 1;
          _weeklyMinutes += minutesRounded;
        }

        // marcar atividade de hoje e recalcular streak
        _activityDays.add(day);
        _streak = _calcStreak(_activityDays.toList());
      });

      // opcional: sincronizar com Firestore (recarrega estados "oficiais")
      // await _loadWeeklyStatsAndStreak();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6EC1E4),
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
                      const SizedBox(height: 30),
                      _buildWeightSection(),
                      const SizedBox(height: 20),
                      SizedBox(height: 180, child: _buildLineChart()),
                      const SizedBox(height: 16),
                      _todayWorkoutCard(),
                      const SizedBox(height: 12),
                      _kpiRow(),
                      const SizedBox(height: 12),
                      _quickActionsRow(), // Atualizado: usa _openCronometer
                      const SizedBox(height: 12),
                      _dailyGoalsChips(),
                      const SizedBox(height: 12),
                      _hydrationCounter(),
                      const SizedBox(height: 12),
                      _insightOfTheDay(),
                      const SizedBox(height: 12),
                      _nextSessionCard(),
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
              fontSize: 22,
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

  Widget _buildWeightSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progresso de Peso',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Pese-se diariamente para acompanhar a sua evolução.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    if (_weightProgress.isEmpty) {
      return const Center(
        child: Text(
          'Sem dados de progresso ainda.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final spots =
        _weightProgress
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value['weight'] as double))
            .toList();
    final dates =
        _weightProgress
            .map((e) => DateFormat('dd/MM').format(e['date'] as DateTime))
            .toList();
    final weights = _weightProgress.map((e) => e['weight'] as double).toList();
    final maxY = (weights.reduce((a, b) => a > b ? a : b)) + 2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems:
                (items) =>
                    items.map((s) {
                      return LineTooltipItem(
                        '${s.y.toStringAsFixed(1)} kg',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList(),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx >= 0 && idx < dates.length) {
                  return Text(
                    dates[idx],
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: const Color(0xFF6EC1E4),
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  // ---------- Cards/Widgets ----------
  Widget _todayWorkoutCard() {
    final user = _user;
    if (user == null) return const SizedBox.shrink();

    final start = _startOfDay(DateTime.now());
    final end = start.add(const Duration(days: 1));

    final q =
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('assigned_workouts')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThan: Timestamp.fromDate(end))
            .limit(1)
            .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: q,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _smallInfoCard('Treino de hoje', 'A carregar…');
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _smallInfoCard(
            'Treino de hoje',
            'Sem sessão marcada. Aproveita para alongar ✨',
          );
        }
        final d = snap.data!.docs.first.data() as Map<String, dynamic>;
        return _actionCard(
          title: d['title'] ?? 'Treino',
          subtitle:
              '${d['exercisesCount'] ?? 0} exercícios • ${d['durationMin'] ?? 0} min',
          cta: 'Começar',
          onTap: () {
            // TODO: navegar para execução do treino específico
          },
        );
      },
    );
  }

  Widget _kpiRow() {
    Widget kpi(String label, String value) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
    return Row(
      children: [
        kpi('Treinos/semana', '$_weeklyWorkouts'),
        const SizedBox(width: 10),
        kpi('Minutos', '$_weeklyMinutes'),
        const SizedBox(width: 10),
        kpi(
          'Peso Δ',
          '${_weeklyWeightDelta >= 0 ? '+' : ''}${_weeklyWeightDelta.toStringAsFixed(1)} kg',
        ),
        const SizedBox(width: 10),
        kpi('Streak', '$_streak'),
      ],
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
            backgroundColor: const Color(0xFF6EC1E4),
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
          onTap:
              _openCronometer, // <- usa o handler que atualiza KPIs ao voltar
        ),
      ],
    );
  }

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
                backgroundColor: Colors.white.withOpacity(0.06),
                selectedColor: const Color(0xFF6EC1E4).withOpacity(0.3),
                onSelected: (sel) async {
                  await docRef.set({...goals, k: sel}, SetOptions(merge: true));
                  // Marcar atividade de hoje se quiseres que metas contem para streak:
                  // setState(() { _activityDays.add(_startOfDay(DateTime.now())); _streak = _calcStreak(_activityDays.toList()); });
                },
                checkmarkColor: Colors.white,
              ),
            ),
          );
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metas do dia',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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
            color: Colors.white.withOpacity(0.06),
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

  Widget _insightOfTheDay() {
    String msg = 'Mantém a consistência 👍';
    if (_weightProgress.length >= 3) {
      final last3 =
          _weightProgress
              .sublist(_weightProgress.length - 3)
              .map((e) => e['weight'] as double)
              .toList();
      if (last3[2] > last3[1] && last3[1] > last3[0]) {
        msg = 'Peso a subir nos últimos dias. Reforça hidratação e sono.';
      } else if (last3[2] < last3[1] && last3[1] < last3[0]) {
        msg = 'Boa! Tendência de descida consistente 👏';
      }
    }
    return _smallInfoCard('Insight do dia', msg);
  }

  Widget _nextSessionCard() {
    final user = _user;
    if (user == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final q =
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('assigned_workouts')
            .where('date', isGreaterThan: Timestamp.fromDate(now))
            .orderBy('date', descending: false)
            .limit(1)
            .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: q,
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _smallInfoCard('Próxima sessão', 'Sem sessões futuras.');
        }
        final d = snap.data!.docs.first.data() as Map<String, dynamic>;
        final dt = (d['date'] as Timestamp).toDate();
        final when = DateFormat('EEE, dd MMM HH:mm', 'pt_PT').format(dt);
        return _smallInfoCard(
          'Próxima sessão',
          '${d['title'] ?? 'Treino'} • $when',
        );
      },
    );
  }

  // ---------- Helpers visuais ----------
  Widget _smallInfoCard(String title, String subtitle) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.06),
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
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Colors.white70)),
      ],
    ),
  );

  Widget _actionCard({
    required String title,
    required String subtitle,
    required String cta,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
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
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6EC1E4),
            ),
            onPressed: onTap,
            child: Text(cta),
          ),
        ],
      ),
    );
  }
}
