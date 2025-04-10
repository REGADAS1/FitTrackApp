import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fit_track_app/data/models/auth/create_user_req.dart';
import 'package:fit_track_app/data/core/configs/theme/assets/app_images.dart';
import 'package:fit_track_app/presentation/auth/pages/select_goal.dart';
import 'package:fit_track_app/presentation/auth/pages/select_weight.dart';

class SelectHeightPage extends StatefulWidget {
  final CreateUserReq createUserReq;

  const SelectHeightPage({Key? key, required this.createUserReq})
    : super(key: key);

  @override
  State<SelectHeightPage> createState() => _SelectHeightPageState();
}

class _SelectHeightPageState extends State<SelectHeightPage> {
  int _selectedMeters = 1;
  int _selectedCentimeters = 70;

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

          // Conteúdo
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
                                  (_) => SelectWeightPage(
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
                  'Seleciona a tua altura',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Scroll wheels
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // METROS
                    SizedBox(
                      width: 100,
                      height: 200,
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 60,
                        diameterRatio: 1.2,
                        perspective: 0.004,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedMeters = index;
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            return Center(
                              child: Text(
                                "$index",
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      index == _selectedMeters
                                          ? Colors.white
                                          : Colors.grey[500],
                                ),
                              ),
                            );
                          },
                          childCount: 3,
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '.',
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // CENTÍMETROS
                    SizedBox(
                      width: 100,
                      height: 200,
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 60,
                        diameterRatio: 1.2,
                        perspective: 0.004,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedCentimeters = index;
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            return Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      index == _selectedCentimeters
                                          ? Colors.white
                                          : Colors.grey[500],
                                ),
                              ),
                            );
                          },
                          childCount: 100,
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        'm',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Botão continuar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final height = double.parse(
                        '${_selectedMeters}.${_selectedCentimeters.toString().padLeft(2, '0')}',
                      );

                      widget.createUserReq.height = height;

                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .set({'height': height}, SetOptions(merge: true));
                      }

                      await Future.delayed(const Duration(milliseconds: 1500));

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => SelectGoalPage(
                                createUserReq: widget.createUserReq,
                              ),
                        ),
                      );
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

              GestureDetector(
                onTap: () async {
                  await Future.delayed(const Duration(milliseconds: 1500));
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => SelectGoalPage(
                            createUserReq: widget.createUserReq,
                          ),
                    ),
                  );
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
