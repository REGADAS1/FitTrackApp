import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewWorkoutsPage extends StatelessWidget {
  final String userEmail;
  final String userName;

  const ViewWorkoutsPage({
    super.key,
    required this.userEmail,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text('Planos de $userName'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: userEmail)
                .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Utilizador não encontrado.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final userData =
              snapshot.data!.docs.first.data() as Map<String, dynamic>?;
          final plans = userData?['plan'] as Map<String, dynamic>?;

          if (plans == null || plans.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum plano encontrado para este aluno.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final allPlans = <Map<String, dynamic>>[];

          plans.forEach((planName, planData) {
            if (planData is Map<String, dynamic>) {
              final exercises =
                  (planData['exercises'] as List?)?.cast<String>() ?? [];
              final muscleGroups =
                  (planData['muscleGroups'] as List?)?.cast<String>() ?? [];

              allPlans.add({
                'name': planName,
                'exercises': exercises,
                'muscleGroups': muscleGroups,
              });
            }
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allPlans.length,
            itemBuilder: (context, index) {
              final plan = allPlans[index];
              final planName = plan['name'];
              final muscleGroups = (plan['muscleGroups'] as List).join(', ');
              final exercises = plan['exercises'] as List;

              return Card(
                color: const Color(0xFF2C2C2C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    planName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    muscleGroups,
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  children:
                      exercises.map<Widget>((exercise) {
                        return ListTile(
                          title: Text(
                            exercise,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        );
                      }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
