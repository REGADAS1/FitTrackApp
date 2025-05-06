import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_track_app/presentation/menus/user_profile_page.dart';
import 'package:fit_track_app/presentation/widgets/sidebar.dart';
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

  double _sidebarXOffset = -250;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadWeightProgress();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
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
    final user = FirebaseAuth.instance.currentUser;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragStart: (details) {
          _isDragging = true;
        },
        onHorizontalDragUpdate: (details) {
          if (_isDragging) {
            setState(() {
              _sidebarXOffset += details.delta.dx;
              _sidebarXOffset = _sidebarXOffset.clamp(-250, 0);
            });
          }
        },
        onHorizontalDragEnd: (details) {
          _isDragging = false;
          setState(() {
            if (_sidebarXOffset > -125) {
              _sidebarXOffset = 0;
            } else {
              _sidebarXOffset = -250;
            }
          });
        },
        child: Stack(
          children: [
            // Conteúdo principal
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 30),
                      _buildWeightSection(),
                      const SizedBox(height: 20),
                      SizedBox(height: 160, child: _buildWeightChart()),
                    ],
                  ),
                ),
              ),
            ),

            // Fundo para fechar a sidebar ao clicar fora
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

            // Sidebar deslizante
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

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserProfilePage()),
            );
          },
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            backgroundImage:
                _profileImage != null
                    ? NetworkImage(_profileImage!)
                    : const AssetImage('assets/images/default_avatar.png')
                        as ImageProvider,
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
          'Acede ao teu perfil e pesa-te diariamente para acompanhares a tua evolução.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildWeightChart() {
    if (_weightProgress.isEmpty) {
      return const Center(
        child: Text(
          'Sem dados de progresso ainda.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final spots =
        _weightProgress.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value['weight']);
        }).toList();

    final labels =
        _weightProgress
            .map((e) => DateFormat('dd/MM').format(e['date']))
            .toList();

    final uniqueWeights =
        _weightProgress.map((e) => e['weight'].toDouble()).toSet().toList()
          ..sort();

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          SizedBox(
            width: spots.length * 60,
            child: LineChart(
              LineChartData(
                backgroundColor: Colors.transparent,
                minY: uniqueWeights.first - 1,
                maxY: uniqueWeights.last + 1,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        int index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              labels[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, _) {
                        if (uniqueWeights.contains(value)) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Text(
                              '${value.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFF6EC1E4),
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    spots: spots,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
