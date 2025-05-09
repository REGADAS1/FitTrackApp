// lib/presentation/menus/dashboard_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_track_app/presentation/menus/chat_page.dart';
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

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatPage()),
    );
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
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 30),
                      _buildWeightSection(),
                      const SizedBox(height: 20),
                      SizedBox(height: 180, child: _buildLineChart()),
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
          'Pese-se diariamente para acompanhar sua evolução.',
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
    final maxY = weights.reduce((a, b) => a > b ? a : b) + 2;

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
            // Só mostra "50 kg"
            getTooltipItems:
                (spots) =>
                    spots.map((s) {
                      return LineTooltipItem(
                        '${s.y.toStringAsFixed(1)} kg',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList(),
          ),
        ),

        titlesData: FlTitlesData(
          // remove eixo Y
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          // eixo X só com data
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
}
