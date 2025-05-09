// lib/presentation/menus/user_profile_page.dart

import 'package:fit_track_app/presentation/auth/pages/signup_or_signin.dart';
import 'package:fit_track_app/presentation/menus/edit_profile_page.dart';
import 'package:fit_track_app/presentation/menus/daily_weight.dart';
import 'package:fit_track_app/presentation/widgets/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String? name;
  String? lastname;
  double? weight;
  double? height;
  String? profileImageUrl;

  double _sidebarXOffset = -250;
  bool _draggingSidebar = false;

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
        weight = data?['weight']?.toDouble();
        height = data?['height']?.toDouble();
        profileImageUrl = data?['profilePictureUrl'];
      });
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignUpOrSignInPage()),
      );
    }
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
      // manual sidebar
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
          setState(() {
            _sidebarXOffset = _sidebarXOffset > -125 ? 0 : -250;
          });
          _draggingSidebar = false;
        },
        child: Stack(
          children: [
            // background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1E1E), Color(0xFF111111)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // menu button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => setState(() => _sidebarXOffset = 0),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // profile avatar (icon fallback)
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white24,
                      backgroundImage:
                          profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : null,
                      child:
                          profileImageUrl == null
                              ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 60,
                              )
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // name centered
                    Text(
                      '${name ?? ''} ${lastname ?? ''}'.trim(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // stats row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Peso',
                            weight != null
                                ? '${weight!.toStringAsFixed(1)} kg'
                                : '--',
                            centered: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Altura',
                            height != null
                                ? '${height!.toStringAsFixed(2)} m'
                                : '--',
                            centered: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    ElevatedButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar Perfil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _registerWeight,
                      icon: const Icon(Icons.monitor_weight_outlined),
                      label: const Text('Pesar-me'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Terminar Sessão'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // overlay to close sidebar
            if (_sidebarXOffset == 0)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _sidebarXOffset = -250),
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),

            // animated sidebar
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

  Widget _buildStatCard(String label, String value, {bool centered = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            value,
            textAlign: centered ? TextAlign.center : TextAlign.left,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: centered ? TextAlign.center : TextAlign.left,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
