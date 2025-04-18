import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fit_track_app/data/models/auth/create_user_req.dart';
import 'package:fit_track_app/presentation/menus/dashboard_page.dart';
import 'package:fit_track_app/presentation/auth/pages/select_weight.dart';
import 'package:fit_track_app/presentation/auth/pages/select_height.dart';
import 'package:fit_track_app/presentation/auth/pages/select_goal.dart';
import 'package:fit_track_app/presentation/auth/pages/select_profile_picture.dart';

class CheckProfilePage extends StatefulWidget {
  const CheckProfilePage({super.key});

  @override
  State<CheckProfilePage> createState() => _CheckProfilePageState();
}

class _CheckProfilePageState extends State<CheckProfilePage> {
  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
  }

  Future<void> _checkProfileStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();

      final firstName = data?['firstName'] ?? '';
      final lastName = data?['lastName'] ?? '';
      final email = user.email ?? '';

      final createUserReq = CreateUserReq(
        name: firstName,
        lastname: lastName,
        email: email,
        password: '',
        weight: data?['weight']?.toDouble(),
        height: data?['height']?.toDouble(),
        goal: data?['goal'],
      );

      await Future.delayed(const Duration(seconds: 3));

      Widget nextPage;
      if (createUserReq.weight == null) {
        nextPage = SelectWeightPage(createUserReq: createUserReq);
      } else if (createUserReq.height == null) {
        nextPage = SelectHeightPage(createUserReq: createUserReq);
      } else if (createUserReq.goal == null) {
        nextPage = SelectGoalPage(createUserReq: createUserReq);
      } else if ((data?['profilePictureUrl'] as String?) == null) {
        nextPage = SelectProfilePicturePage(createUserReq: createUserReq);
      } else {
        nextPage = const DashboardPage();
      }

      _fadeToPage(nextPage);
    }
  }

  void _fadeToPage(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = Tween(begin: 0.0, end: 1.0).animate(animation);
          return FadeTransition(opacity: fade, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 5,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            const SizedBox(height: 20),
            Text(
              'A verificar perfil...',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
