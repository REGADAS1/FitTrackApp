import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_track_app/data/core/configs/theme/assets/app_images.dart';
import 'package:fit_track_app/presentation/menus/dashboard_page.dart';

class RegisterDailyWeightPage extends StatefulWidget {
  const RegisterDailyWeightPage({super.key});

  @override
  State<RegisterDailyWeightPage> createState() =>
      _RegisterDailyWeightPageState();
}

class _RegisterDailyWeightPageState extends State<RegisterDailyWeightPage> {
  int _selectedKg = 70;
  int _selectedGrams = 0;

  Future<void> _saveWeight() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final weight = double.parse('$_selectedKg.${_selectedGrams}');
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final weightsRef = userRef.collection('weights');

    final existing =
        await weightsRef
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
            )
            .where('date', isLessThan: Timestamp.fromDate(todayEnd))
            .get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Já registaste o peso hoje.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await weightsRef.add({
      'date': Timestamp.fromDate(todayStart),
      'weight': weight,
    });

    await userRef.set({'weight': weight}, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Peso registado com sucesso!'),
        backgroundColor: Colors.green[600],
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    }
  }

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

          // SETA VOLTAR
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 12),
              child: ClipOval(
                child: Material(
                  color: Colors.white.withOpacity(0.2),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
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

          Column(
            children: [
              const SizedBox(height: 100),
              const Center(
                child: Text(
                  'Regista o teu peso de hoje',
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

              // BOTÃO "Guardar"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveWeight,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Guardar Peso',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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
