import 'package:flutter/material.dart';
import 'package:fit_track_app/data/models/auth/create_user_req.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fit_track_app/data/core/configs/theme/assets/app_images.dart';
import 'package:fit_track_app/presentation/auth/pages/select_height.dart';

class SelectWeightPage extends StatefulWidget {
  final CreateUserReq createUserReq;

  const SelectWeightPage({Key? key, required this.createUserReq})
    : super(key: key);

  @override
  _SelectWeightPageState createState() => _SelectWeightPageState();
}

class _SelectWeightPageState extends State<SelectWeightPage> {
  int _selectedKg = 70;
  int _selectedGrams = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND
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
              const SizedBox(height: 80),

              // Título
              const Center(
                child: Text(
                  'Seleciona o teu peso',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // SCROLL WHEELS
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // KG
                    SizedBox(
                      width: 100,
                      height: 200,
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 60,
                        diameterRatio: 1.2,
                        perspective: 0.004,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedKg = index + 30;
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            final kg = index + 30;
                            return Center(
                              child: Text(
                                "$kg",
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      kg == _selectedKg
                                          ? Colors.white
                                          : Colors.grey[500],
                                ),
                              ),
                            );
                          },
                          childCount: 151,
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

                    // GRAMAS
                    SizedBox(
                      width: 100,
                      height: 200,
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 60,
                        diameterRatio: 1.2,
                        perspective: 0.004,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedGrams = index;
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
                                      index == _selectedGrams
                                          ? Colors.white
                                          : Colors.grey[500],
                                ),
                              ),
                            );
                          },
                          childCount: 10,
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        'kg',
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

              // BOTÃO "Continuar"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final weight = double.parse(
                        '$_selectedKg.${_selectedGrams}',
                      );

                      widget.createUserReq.weight = weight;

                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .set({'weight': weight}, SetOptions(merge: true));
                      }

                      await Future.delayed(const Duration(milliseconds: 1500));

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

              // AGORA NÃO
              GestureDetector(
                onTap: () async {
                  await Future.delayed(const Duration(milliseconds: 150));
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
