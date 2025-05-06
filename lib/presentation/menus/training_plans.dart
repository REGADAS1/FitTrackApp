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
  final List<Map<String, dynamic>> _allPlans = [];
  bool _loading = true;

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
      setState(() {
        _loading = false;
      });
      return;
    }

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final userData = doc.data();

    if (userData == null || !userData.containsKey('plan')) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final userPlans = userData['plan'] as Map<String, dynamic>?;
    final String userName =
        '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}';

    if (userPlans != null) {
      for (var entry in userPlans.entries) {
        final planName = entry.key;
        final planData = entry.value;

        if (planData is Map<String, dynamic>) {
          final exercises =
              (planData['exercises'] as List?)?.cast<String>() ?? [];
          final muscleGroups =
              (planData['muscleGroups'] as List?)?.cast<String>() ?? [];

          _allPlans.add({
            'user': userName,
            'name': planName,
            'muscleGroups': muscleGroups,
            'exercises': exercises,
            'imageUrl': _getImageForGroup(muscleGroups),
          });
        }
      }
    }

    setState(() {
      _loading = false;
    });
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
    return 'assets/images/nvrtap_white.png'; // imagem default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1E1E), Color(0xFF111111)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child:
                      _loading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                          : _allPlans.isEmpty
                          ? const Center(
                            child: Text(
                              'Ainda não tem planos de treino atribuídos.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Planos de Treino',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _allPlans.length,
                                  itemBuilder: (context, index) {
                                    return _buildPlanCard(_allPlans[index]);
                                  },
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ),

            // Fechar sidebar ao clicar fora
            if (_sidebarXOffset == 0)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _sidebarXOffset = -250;
                    });
                  },
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
                onClose: () {
                  setState(() {
                    _sidebarXOffset = -250;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: DecorationImage(
          image:
              plan['imageUrl'].startsWith('assets/')
                  ? AssetImage(plan['imageUrl']) as ImageProvider
                  : NetworkImage(plan['imageUrl']),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.darken,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        collapsedIconColor: Colors.white70,
        iconColor: Colors.white70,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        title: Text(
          plan['name'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          plan['muscleGroups'].join(', '),
          style: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
        children:
            (plan['exercises'] as List<String>).map((exercise) {
              return ListTile(
                title: Text(
                  exercise,
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            }).toList(),
      ),
    );
  }
}
