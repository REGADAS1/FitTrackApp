import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PTDashboardPage extends StatelessWidget {
  const PTDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard da PT')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alunos da Aplicação',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final fullName =
                          '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}';
                      final profileUrl = data['profilePictureUrl'];

                      return Card(
                        color: const Color(0xFF2C2C2C),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                profileUrl != null
                                    ? NetworkImage(profileUrl)
                                    : const AssetImage(
                                          'assets/images/default_avatar.png',
                                        )
                                        as ImageProvider,
                            radius: 25,
                          ),
                          title: Text(
                            fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Peso: ${data['weight'] ?? '--'} kg',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                'Altura: ${data['height'] ?? '--'} m',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                'Objetivo: ${data['goal'] ?? '--'}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
