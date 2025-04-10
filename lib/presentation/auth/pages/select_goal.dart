import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fit_track_app/data/models/auth/create_user_req.dart';
import 'package:fit_track_app/data/core/configs/theme/assets/app_images.dart';
import 'package:fit_track_app/presentation/auth/pages/select_height.dart';

class SelectGoalPage extends StatefulWidget {
  final CreateUserReq createUserReq;

  const SelectGoalPage({Key? key, required this.createUserReq})
    : super(key: key);

  @override
  State<SelectGoalPage> createState() => _SelectGoalPageState();
}

class _SelectGoalPageState extends State<SelectGoalPage> {
  String? _selectedGoal;

  final List<Map<String, dynamic>> _goals = [
    {'label': 'Perder peso', 'icon': Icons.directions_run},
    {'label': 'Ganhar massa muscular', 'icon': Icons.fitness_center},
    {'label': 'Manter forma', 'icon': Icons.self_improvement},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppImages.signupOrsigninBG),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 40),

              // SETA FANCY PARA TRÁS
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ClipOval(
                    child: Material(
                      color: Colors.white.withOpacity(0.2),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => SelectHeightPage(
                                    createUserReq: widget.createUserReq,
                                  ),
                            ),
                          );
                        },
                        splashColor: Colors.white30,
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Center(
                child: Text(
                  'Qual é o teu objetivo?',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Lista de opções
              ..._goals.map((goal) {
                final isSelected = _selectedGoal == goal['label'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGoal = goal['label'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.white.withOpacity(0.9)
                              : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          goal['icon'],
                          size: 30,
                          color: isSelected ? Colors.black87 : Colors.white,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            goal['label'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.black87 : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const Spacer(),

              // Botão continuar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _selectedGoal == null
                            ? null
                            : () async {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null && _selectedGoal != null) {
                                widget.createUserReq.goal = _selectedGoal;

                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .set({
                                      'goal': _selectedGoal,
                                    }, SetOptions(merge: true));

                                Navigator.pushReplacementNamed(
                                  context,
                                  '/dashboard',
                                );
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Agora não
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
                child: const Text(
                  'Agora Não',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }
}
