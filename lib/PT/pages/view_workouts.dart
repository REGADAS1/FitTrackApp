// lib/presentation/menus/view_workouts_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewWorkoutsPage extends StatelessWidget {
  final String userId; // <- usa o mesmo id que usaste ao guardar
  final String userName;

  const ViewWorkoutsPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  Future<void> _confirmAndDeletePlan(
    BuildContext context,
    String planName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              'Remover plano',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Tem a certeza que quer remover o plano "$planName"?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Não'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sim'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final ref = FirebaseFirestore.instance.collection('users').doc(userId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = (snap.data() as Map<String, dynamic>?) ?? {};
      final Map<String, dynamic> plans = Map<String, dynamic>.from(
        (data['plans'] as Map?) ?? {},
      );
      plans.remove(planName);
      tx.update(ref, {'plans': plans});
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plano "$planName" removido.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text('Planos de $userName'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Utilizador não encontrado.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          // 👇 chave correta: "plans" (plural)
          final Map<String, dynamic> plans =
              (userData['plans'] as Map<String, dynamic>?) ?? {};

          if (plans.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum plano encontrado para este aluno.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          // Converte o mapa de planos num array para ListView
          final allPlans =
              plans.entries.map((e) {
                final String planName = e.key;
                final Map<String, dynamic> planData =
                    (e.value as Map<String, dynamic>?) ?? {};
                final List<dynamic> exercises =
                    (planData['exercises'] as List?) ?? const [];
                final List<String> muscleGroups =
                    (planData['muscleGroups'] as List?)?.cast<String>() ??
                    const [];
                final DateTime? assignedAt =
                    (planData['assignedAt'] is Timestamp)
                        ? (planData['assignedAt'] as Timestamp).toDate()
                        : null;

                return {
                  'name': planName,
                  'exercises': exercises,
                  'muscleGroups': muscleGroups,
                  'assignedAt': assignedAt,
                };
              }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allPlans.length,
            itemBuilder: (context, index) {
              final plan = allPlans[index];
              final String planName = plan['name'] as String;
              final String muscleGroups = (plan['muscleGroups'] as List).join(
                ', ',
              );
              final List exercises = plan['exercises'] as List;
              final DateTime? assignedAt = plan['assignedAt'] as DateTime?;

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
                  // 👇 ícone de lixo à direita + indicador de expandir
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Remover plano',
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed:
                            () => _confirmAndDeletePlan(context, planName),
                      ),
                      const Icon(Icons.expand_more, color: Colors.white70),
                    ],
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
                    [
                      if (muscleGroups.isNotEmpty) muscleGroups,
                      if (assignedAt != null)
                        ' • atribuído em ${_ddMMyyyyHHmm(assignedAt)}',
                    ].join(''),
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  children:
                      exercises.map<Widget>((raw) {
                        // cada exercício é um Map (não uma String)
                        final Map<String, dynamic> ex =
                            Map<String, dynamic>.from(raw as Map);

                        final String name =
                            (ex['name'] ?? '(Sem nome)').toString();
                        final String group =
                            (ex['muscleGroup'] ?? 'Outros').toString();
                        final bool usePyramid =
                            (ex['usePyramid'] as bool?) ?? false;

                        Widget trailing;
                        if (usePyramid) {
                          final List pyramid =
                              (ex['pyramid'] as List?) ?? const [];
                          final pyramidText = pyramid
                              .map((p) {
                                final m = Map<String, dynamic>.from(p as Map);
                                final w = m['weight'] ?? 0;
                                final r = m['reps'] ?? 0;
                                return '${w}kg x$r';
                              })
                              .join(' · ');
                          trailing = Text(
                            pyramidText.isEmpty ? 'Pirâmide' : pyramidText,
                            style: const TextStyle(color: Colors.white54),
                          );
                        } else {
                          final sets = (ex['sets'] as int?) ?? 3;
                          final reps = (ex['reps'] as int?) ?? 10;
                          trailing = Text(
                            '${sets}x$reps',
                            style: const TextStyle(color: Colors.white54),
                          );
                        }

                        return ListTile(
                          title: Text(
                            name,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          subtitle: Text(
                            group,
                            style: const TextStyle(color: Colors.white38),
                          ),
                          trailing: trailing,
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

  String _ddMMyyyyHHmm(DateTime d) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
