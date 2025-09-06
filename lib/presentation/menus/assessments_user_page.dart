import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fit_track_app/presentation/widgets/sidebar.dart';

class AssessmentsUserPage extends StatefulWidget {
  const AssessmentsUserPage({super.key});

  @override
  State<AssessmentsUserPage> createState() => _AssessmentsUserPageState();
}

class _AssessmentsUserPageState extends State<AssessmentsUserPage> {
  static const Color themeBlue = Color(0xFF6EC1E4);

  // Sidebar deslizável (igual ao calendário)
  double _sidebarXOffset = -250;
  bool _isDragging = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot<Map<String, dynamic>>> _assessmentsStream() {
    final uid = _user?.uid;
    if (uid == null) {
      // evita crashes se ainda não houver sessão
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('assessments')
        .orderBy('date', descending: true)
        .snapshots();
  }

  String _fmtDateTime(DateTime dt) =>
      DateFormat('EEE • dd/MM/yyyy • HH:mm', 'pt_PT').format(dt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // interacção da sidebar (puxe para abrir/fechar)
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
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: _assessmentsStream(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                final docs = snapshot.data?.docs ?? [];
                                if (docs.isEmpty) {
                                  return _emptyState();
                                }
                                return ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  itemCount: docs.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, i) {
                                    final data = docs[i].data();
                                    final date =
                                        (data['date'] as Timestamp?)?.toDate();
                                    return _assessmentCard(data, date);
                                  },
                                );
                              },
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

  // ---------- UI blocks ----------

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
              'Avaliações',
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
          'Ainda não tens avaliações registadas pelo teu PT.',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _assessmentCard(Map<String, dynamic> data, DateTime? date) {
    // helper para construir chips de forma segura
    List<Widget> chips = [];
    void addChip(String label, dynamic value, {String? suffix}) {
      if (value == null || (value is String && value.trim().isEmpty)) return;
      final text =
          value is num
              ? value.toStringAsFixed(value % 1 == 0 ? 0 : 1)
              : value.toString();
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Chip(
            backgroundColor: Colors.white.withOpacity(0.07),
            label: Text(
              '$label $text${suffix ?? ''}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    addChip('Peso:', data['peso'], suffix: ' kg');
    addChip('Gord. visceral:', data['gorduraVisceral']);
    addChip('% Magra:', data['massaMagraPct'], suffix: ' %');
    addChip('% Gorda:', data['massaGordaPct'], suffix: ' %');
    addChip('Cintura:', data['cinturaCm'], suffix: ' cm');
    addChip('Anca:', data['ancaCm'], suffix: ' cm');
    addChip('Peito:', data['peitoCm'], suffix: ' cm');

    final notes = (data['notes'] as String?)?.trim();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com data/hora
            Row(
              children: [
                const Icon(Icons.event, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  date != null ? _fmtDateTime(date) : 'Sem data',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(children: chips),

            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.sticky_note_2_outlined,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
