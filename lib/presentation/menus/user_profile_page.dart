// lib/presentation/menus/user_profile_page.dart

import 'package:fit_track_app/presentation/auth/pages/signup_or_signin.dart';
import 'package:fit_track_app/presentation/menus/edit_profile_page.dart';
import 'package:fit_track_app/presentation/menus/daily_weight.dart';
import 'package:fit_track_app/presentation/widgets/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fit_track_app/presentation/splash/pages/splash.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  static const Color themeBlue = Color(0xFF6EC1E4);

  String? name;
  String? lastname;
  double? weight;
  double? height;
  String? profileImageUrl;

  DateTime? _lastAssessmentAt;

  double _sidebarXOffset = -250;
  bool _draggingSidebar = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();

      setState(() {
        name = data?['firstName'] ?? '';
        lastname = data?['lastName'] ?? '';
        weight = (data?['weight'] as num?)?.toDouble();
        height = (data?['height'] as num?)?.toDouble();
        profileImageUrl = data?['profilePictureUrl'];
      });

      await _loadLastAssessmentDate(user.uid);
      setState(() => _loading = false);
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadLastAssessmentDate(String uid) async {
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('assessments')
              .orderBy('date', descending: true)
              .limit(1)
              .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        final Timestamp? tsMeasured = data['measuredAt'] as Timestamp?;
        final Timestamp? tsDate = data['date'] as Timestamp?;
        final DateTime? when = (tsMeasured ?? tsDate)?.toDate();
        if (when != null) {
          setState(() => _lastAssessmentAt = when);
        }
      }
    } catch (_) {
      // Silenciar se coleção/campos não existirem
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    // Mostra a SplashPage por ~3s e DEPOIS navega sozinha para GetStartedPage.
    // Limpamos toda a pilha para reiniciar o fluxo normal.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashPage(autoNavigate: true)),
      (route) => false,
    );
  }

  Future<void> _confirmLogout() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: _glassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Terminar sessão?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vais sair da tua conta. Podes voltar a entrar quando quiseres.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // NÃO — estilo "Pesar-me" (outline branco)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, color: Colors.white),
                          label: const Text(
                            'Não',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // SIM — estilo "Terminar sessão" (outline vermelho)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _logout();
                          },
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            'Sim',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.redAccent,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editProfile() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
  }

  void _registerWeight() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterDailyWeightPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragStart: (_) => _draggingSidebar = true,
        onHorizontalDragUpdate: (details) {
          if (_draggingSidebar) {
            setState(() {
              _sidebarXOffset = (_sidebarXOffset + details.delta.dx).clamp(
                -250,
                0,
              );
            });
          }
        },
        onHorizontalDragEnd: (_) {
          setState(() => _sidebarXOffset = _sidebarXOffset > -125 ? 0 : -250);
          _draggingSidebar = false;
        },
        child: Stack(
          children: [
            // fundo
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1E1E), Color(0xFF111111)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // conteúdo
            SafeArea(
              child:
                  _loading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                      : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _topBar(),
                            const SizedBox(height: 12),
                            _headerCard(),
                            const SizedBox(height: 16),
                            _sectionTitle('Métricas'),
                            const SizedBox(height: 8),
                            _metricsGrid(),
                            const SizedBox(height: 24),
                            _actionsCard(),
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

            // sidebar
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

  // ---------- UI helpers ----------

  Widget _topBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => setState(() => _sidebarXOffset = 0),
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'Perfil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerCard() {
    final imageProvider =
        profileImageUrl != null ? NetworkImage(profileImageUrl!) : null;

    return _glassCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white24,
            backgroundImage: imageProvider,
            child:
                imageProvider == null
                    ? const Icon(Icons.person, color: Colors.white, size: 50)
                    : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ('${name ?? ''} ${lastname ?? ''}').trim().isEmpty
                      ? 'Utilizador'
                      : ('${name ?? ''} ${lastname ?? ''}').trim(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mantém os teus dados sempre atualizados.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: const Text(
                      'Editar perfil',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Grade de métricas
  Widget _metricsGrid() {
    final bmi =
        (weight != null && height != null && height! > 0)
            ? (weight! / (height! * height!))
            : null;

    final lastAssessmentStr =
        _lastAssessmentAt != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(_lastAssessmentAt!)
            : '—';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricTile(
                title: 'Peso',
                value:
                    weight != null ? '${weight!.toStringAsFixed(1)} kg' : '—',
                icon: Icons.monitor_weight_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricTile(
                title: 'Altura',
                value: height != null ? '${height!.toStringAsFixed(2)} m' : '—',
                icon: Icons.height,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricTile(
                title: 'IMC',
                value: bmi != null ? bmi.toStringAsFixed(1) : '—',
                icon: Icons.health_and_safety_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricTile(
                title: 'Última avaliação',
                value: lastAssessmentStr,
                icon: Icons.event_available_outlined,
                valueTextSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricTile({
    required String title,
    required String value,
    required IconData icon,
    double valueTextSize = 18,
  }) {
    return _glassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: valueTextSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsCard() {
    return _glassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          // Pesar-me — OUTLINE branco
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _registerWeight,
              icon: const Icon(
                Icons.monitor_weight_outlined,
                color: Colors.white,
              ),
              label: const Text(
                'Pesar-me',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Terminar sessão — abre confirmação
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text(
                'Terminar sessão',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _glassCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
