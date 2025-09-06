// lib/presentation/menus/training_plans_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_track_app/presentation/widgets/sidebar.dart';
import 'package:flutter/material.dart';

class TrainingPlansPage extends StatefulWidget {
  const TrainingPlansPage({super.key});

  @override
  State<TrainingPlansPage> createState() => _TrainingPlansPageState();
}

class _TrainingPlansPageState extends State<TrainingPlansPage> {
  static const Color themeBlue = Color(0xFF6EC1E4);

  final List<Map<String, dynamic>> _allPlans = [];
  bool _loading = true;

  // Sidebar deslizável (igual ao calendário / feed)
  double _sidebarXOffset = -250;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadUserPlans();
  }

  Future<void> _loadUserPlans() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final userData = doc.data();
    if (userData == null || !userData.containsKey('plans')) {
      setState(() => _loading = false);
      return;
    }

    final userPlans = userData['plans'] as Map<String, dynamic>;
    final userName =
        '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();

    _allPlans.clear();
    for (var entry in userPlans.entries) {
      final planName = entry.key;
      final planData = entry.value as Map<String, dynamic>;

      final exercisesData =
          (planData['exercises'] as List).cast<Map<String, dynamic>>();
      final muscleGroups = (planData['muscleGroups'] as List).cast<String>();

      _allPlans.add({
        'user': userName,
        'name': planName,
        'muscleGroups': muscleGroups,
        'exercises': exercisesData,
        'imageUrl': _getImageForGroup(muscleGroups),
      });
    }

    setState(() => _loading = false);
  }

  String _getImageForGroup(List<String> groups) {
    if (groups.any((g) => g.toLowerCase().contains('peito'))) {
      return 'assets/images/chest_background.png';
    } else if (groups.any((g) => g.toLowerCase().contains('perna'))) {
      return 'assets/images/legs_background.png';
    } else if (groups.any((g) => g.toLowerCase().contains('costas'))) {
      return 'assets/images/back_background.png';
    } else if (groups.any(
      (g) =>
          g.toLowerCase().contains('braço') ||
          g.toLowerCase().contains('bíceps') ||
          g.toLowerCase().contains('tríceps'),
    )) {
      return 'assets/images/arms_background.png';
    } else if (groups.any((g) => g.toLowerCase().contains('ombros'))) {
      return 'assets/images/shoulder_background.png';
    }
    return 'assets/images/nvrtap_white.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // gesto de abrir/fechar sidebar
        onHorizontalDragStart: (_) => _isDragging = true,
        onHorizontalDragUpdate: (details) {
          if (_isDragging) {
            setState(() {
              _sidebarXOffset = (_sidebarXOffset + details.delta.dx).clamp(
                -250,
                0,
              );
            });
          }
        },
        onHorizontalDragEnd: (_) {
          _isDragging = false;
          setState(() => _sidebarXOffset = _sidebarXOffset > -125 ? 0 : -250);
        },
        child: Stack(
          children: [
            // Fundo
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1E1E), Color(0xFF111111)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _topBar(),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child:
                            _loading
                                ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                                : _allPlans.isEmpty
                                ? _emptyState()
                                : ListView.separated(
                                  padding: const EdgeInsets.only(
                                    bottom: 24,
                                    top: 4,
                                  ),
                                  itemCount: _allPlans.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 16),
                                  itemBuilder:
                                      (ctx, idx) =>
                                          _PlanCard(plan: _allPlans[idx]),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // overlay para fechar sidebar
            if (_sidebarXOffset == 0)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _sidebarXOffset = -250),
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),

            // Sidebar
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

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => setState(() => _sidebarXOffset = 0),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Planos de Treino',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Ainda não tens planos de treino atribuídos.',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// ---------- CARD DO PLANO (com estética “apetecível”) ----------
class _PlanCard extends StatefulWidget {
  final Map<String, dynamic> plan;
  const _PlanCard({required this.plan});

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> with TickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final List<String> muscleGroups =
        (plan['muscleGroups'] as List).cast<String>();
    final List<Map<String, dynamic>> exercises =
        (plan['exercises'] as List).cast<Map<String, dynamic>>();

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          image: DecorationImage(
            image:
                plan['imageUrl'].toString().startsWith('assets/')
                    ? AssetImage(plan['imageUrl']) as ImageProvider
                    : NetworkImage(plan['imageUrl']),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.45),
              BlendMode.darken,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          // véu subtil
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho: nome + estado expandido
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan['name'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.expand_more,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Chips de grupos musculares
                    Wrap(
                      spacing: 8,
                      runSpacing: -6,
                      children:
                          muscleGroups
                              .map(
                                (g) => Chip(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.08,
                                  ),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                  label: Text(
                                    g,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),

                    // Lista de exercícios quando expandido
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 230),
                      child:
                          !_expanded
                              ? const SizedBox(height: 6)
                              : Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                  children:
                                      exercises
                                          .map((e) => _ExerciseRow(ex: e))
                                          .toList(),
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- LINHA DE EXERCÍCIO BONITA ----------
class _ExerciseRow extends StatelessWidget {
  final Map<String, dynamic> ex;
  const _ExerciseRow({required this.ex});

  @override
  Widget build(BuildContext context) {
    final hasPyramid = ex.containsKey('pyramid') && ex['pyramid'] is List;
    final String name = (ex['name'] ?? '').toString();

    // Badges básicos (sets × reps) quando não é pirâmide
    Widget badges;
    if (!hasPyramid) {
      final sets = ex['sets'];
      final reps = ex['reps'];
      final rest = ex['restSec'];
      badges = Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _badge('${sets ?? '-'} séries'),
          _badge('${reps ?? '-'} reps'),
          if (rest != null) _badge('${rest}s descanso', subtle: true),
        ],
      );
    } else {
      // pirâmide: lista compacta peso × reps
      final pyramid =
          (ex['pyramid'] as List)
              .cast<Map<String, dynamic>>(); // [{weight, reps}]
      badges = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  pyramid
                      .asMap()
                      .entries
                      .map(
                        (entry) => Padding(
                          padding: EdgeInsets.only(
                            bottom: entry.key == pyramid.length - 1 ? 0 : 6,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.timeline,
                                size: 16,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${entry.value['weight']} kg  ×  ${entry.value['reps']}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      );
    }

    final notes = (ex['notes'] ?? '').toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + ícone
          Row(
            children: [
              const Icon(Icons.fitness_center, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          badges,
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notes_outlined,
                  size: 16,
                  color: Colors.white54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notes,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(String text, {bool subtle = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            subtle
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFF6EC1E4).withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: subtle ? Colors.white12 : const Color(0xFF6EC1E4),
          width: subtle ? 1 : 1.3,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: subtle ? Colors.white70 : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
